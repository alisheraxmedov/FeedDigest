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

/// Strips trailing user turns that never received a model reply (e.g. a failed
/// send). Gemini's multi-turn format must not contain two consecutive user
/// roles — which is exactly what happens if an orphaned user turn stays in the
/// history and a new question is appended after it.
List<ChatMessage> sanitizeChatHistory(List<ChatMessage> messages) {
  var end = messages.length;
  while (end > 0 && messages[end - 1].isUser) {
    end--;
  }
  return messages.sublist(0, end);
}

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
    // History for the request drops any orphaned trailing user turn; the new
    // question is sent separately so the payload alternates user/model roles.
    final history = sanitizeChatHistory(state.messages);
    state = ChatState(
      messages: [
        ...state.messages,
        ChatMessage(role: ChatRole.user, text: q),
      ],
      sending: true,
    );
    try {
      final body = await ref.read(articleBodyProvider(article).future);
      if (!ref.mounted) return;
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
      if (!ref.mounted) return;
      state = ChatState(
        messages: [
          ...state.messages,
          ChatMessage(role: ChatRole.model, text: answer),
        ],
      );
    } on GeminiException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        sending: false,
        errorCode: e.code == 'no_key' ? 'no_key' : 'error',
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(sending: false, errorCode: 'error');
    }
  }
}
