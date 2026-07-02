import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/prefs/preferences.dart';
import '../../../core/providers.dart';
import '../../../models/ai_summary.dart';
import '../../../models/article.dart';
import '../../feed/viewmodel/article_body_viewmodel.dart';

final summaryViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<SummaryViewModel, String, Article>(SummaryViewModel.new);

class SummaryViewModel extends AsyncNotifier<String> {
  SummaryViewModel(this.article);

  final Article article;

  @override
  Future<String> build() async {
    final lang = ref.watch(effectiveAiLangProvider);
    final cacheKey = '${article.id}-${lang.code}';
    final cache = ref.read(summaryCacheRepositoryProvider);
    final cached = cache.get(cacheKey);
    if (cached != null) return cached.summary;
    // Resolve the full readable body first — link posts (e.g. Hacker News) have
    // no feed text, so summarizing the bare article would only feed the URL to
    // the model. articleBodyProvider fetches/extracts it (and is shared with the
    // detail screen, so it isn't fetched twice).
    final fullBody = await ref.read(articleBodyProvider(article).future);
    final enriched = fullBody.trim().isNotEmpty
        ? article.copyWith(body: fullBody)
        : article;
    final text = await ref
        .read(geminiRepositoryProvider)
        .summarize(enriched, langCode: lang.code);
    await cache.put(AiSummary(postId: cacheKey, summary: text));
    return text;
  }
}
