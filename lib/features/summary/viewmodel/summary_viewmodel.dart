import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../models/ai_summary.dart';
import '../../../models/reddit_post.dart';

final summaryViewModelProvider =
    AsyncNotifierProvider.family<SummaryViewModel, String, RedditPost>(
        SummaryViewModel.new);

class SummaryViewModel extends AsyncNotifier<String> {
  SummaryViewModel(this.post);

  final RedditPost post;

  @override
  Future<String> build() async {
    final cache = ref.read(summaryCacheRepositoryProvider);
    final cached = cache.get(post.id);
    if (cached != null) return cached.summary;
    final text = await ref.read(geminiRepositoryProvider).summarize(post);
    await cache.put(AiSummary(postId: post.id, summary: text));
    return text;
  }
}
