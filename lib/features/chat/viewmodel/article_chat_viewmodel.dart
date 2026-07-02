/*
Per-article chat state. Each send appends the user's question, calls Gemini with
the article as grounding context plus the prior turns, then appends the reply.
Errors surface as an errorCode the view localizes (no localized text lives here).
*/
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/prefs/preferences.dart';
import '../../../core/providers.dart';
import '../../../data/gemini_repository.dart';
import '../../../models/article.dart';
import '../../../models/chat_message.dart';
import '../../feed/viewmodel/article_body_viewmodel.dart';

@immutable
class ChatState {
  const ChatState({
    this.messages = const [],
    this.sending = false,
    this.errorCode,
  });

  final List<ChatMessage> messages;
  final bool sending;
  final String? errorCode;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? sending,
    String? errorCode,
  }) => ChatState(
    messages: messages ?? this.messages,
    sending: sending ?? this.sending,
    errorCode: errorCode,
  );
}

final articleChatProvider = NotifierProvider.autoDispose
    .family<ArticleChatViewModel, ChatState, Article>(ArticleChatViewModel.new);

class ArticleChatViewModel extends Notifier<ChatState> {
  ArticleChatViewModel(this.article);

  final Article article;

  @override
  ChatState build() => const ChatState();

  Future<void> send(String question) async {
    final q = question.trim();
    if (q.isEmpty || state.sending) return;
    final history = state.messages;
    state = ChatState(
      messages: [
        ...history,
        ChatMessage(role: ChatRole.user, text: q),
      ],
      sending: true,
    );
    try {
      final body = await ref.read(articleBodyProvider(article).future);
      final lang = ref.read(effectiveAiLangProvider);
      final answer = await ref
          .read(geminiRepositoryProvider)
          .chat(
            article: article,
            articleBody: body,
            history: history,
            question: q,
            langCode: lang.code,
          );
      state = ChatState(
        messages: [
          ...state.messages,
          ChatMessage(role: ChatRole.model, text: answer),
        ],
      );
    } on GeminiException catch (e) {
      state = state.copyWith(
        sending: false,
        errorCode: e.code == 'no_key' ? 'no_key' : 'error',
      );
    } catch (_) {
      state = state.copyWith(sending: false, errorCode: 'error');
    }
  }
}
