/*
Holds the on-demand full-article translation state for the detail screen. The
translated body is fetched lazily the first time the reader turns translation on
(reusing articleBodyProvider for the source text) and then cached in state so
toggling back and forth is free.
*/
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/prefs/preferences.dart';
import '../../../core/providers.dart';
import '../../../models/article.dart';
import 'article_body_viewmodel.dart';

@immutable
class TranslationState {
  const TranslationState({
    this.showing = false,
    this.text,
    this.loading = false,
    this.error = false,
  });

  /// Whether the translated body is currently displayed instead of the original.
  final bool showing;
  final String? text;
  final bool loading;
  final bool error;

  TranslationState copyWith({
    bool? showing,
    String? text,
    bool? loading,
    bool? error,
  }) => TranslationState(
    showing: showing ?? this.showing,
    text: text ?? this.text,
    loading: loading ?? this.loading,
    error: error ?? this.error,
  );
}

final articleTranslationProvider = NotifierProvider.autoDispose
    .family<ArticleTranslationViewModel, TranslationState, Article>(
      ArticleTranslationViewModel.new,
    );

class ArticleTranslationViewModel extends Notifier<TranslationState> {
  ArticleTranslationViewModel(this.article);

  final Article article;

  @override
  TranslationState build() => const TranslationState();

  /// Toggles between the original and the translated body, translating on first
  /// use. The target language is the user's AI-summary language.
  Future<void> toggle() async {
    if (state.showing) {
      state = state.copyWith(showing: false);
      return;
    }
    if (state.text != null) {
      state = state.copyWith(showing: true, error: false);
      return;
    }
    state = const TranslationState(showing: true, loading: true);
    try {
      final body = await ref.read(articleBodyProvider(article).future);
      if (!ref.mounted) return;
      final lang = ref.read(effectiveAiLangProvider);
      final translated = await ref
          .read(geminiRepositoryProvider)
          .translate(body, targetLangCode: lang.code);
      if (!ref.mounted) return;
      state = TranslationState(showing: true, text: translated);
    } catch (_) {
      if (!ref.mounted) return;
      state = const TranslationState(showing: true, error: true);
    }
  }
}
