import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/prefs/preferences.dart';
import '../../../core/providers.dart';
import '../../../models/ai_summary.dart';
import '../../../models/article.dart';

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
    final text = await ref
        .read(geminiRepositoryProvider)
        .summarize(article, langCode: lang.code);
    await cache.put(AiSummary(postId: cacheKey, summary: text));
    return text;
  }
}
