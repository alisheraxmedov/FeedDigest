/*
DigestViewModel builds a single "today's top stories" AI digest from the current
feed's top articles. It reuses the summary cache (keyed by language + the set of
article ids) so reopening the same feed doesn't re-spend the user's Gemini quota.
*/
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ai/ai_client.dart';
import '../../../core/prefs/preferences.dart';
import '../../../core/providers.dart';
import '../../../models/ai_summary.dart';
import '../../feed/viewmodel/feed_viewmodel.dart';

/// How many top articles feed the daily digest.
const int kDigestSize = 5;

final digestViewModelProvider =
    AsyncNotifierProvider.autoDispose<DigestViewModel, String>(
      DigestViewModel.new,
    );

class DigestViewModel extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final lang = ref.watch(effectiveAiLangProvider);
    final feed = ref.read(feedViewModelProvider).value;
    final top = (feed?.items ?? const []).take(kDigestSize).toList();
    if (top.isEmpty) {
      throw AiException('empty');
    }
    final ids = top.map((a) => a.id).join('|');
    final cacheKey = 'digest-${lang.code}-${ids.hashCode}';
    final cache = ref.read(summaryCacheRepositoryProvider);
    final cached = cache.get(cacheKey);
    if (cached != null) return cached.summary;
    final text = await ref
        .read(aiRepositoryProvider)
        .digest(top, langCode: lang.code);
    await cache.put(AiSummary(postId: cacheKey, summary: text));
    return text;
  }
}
