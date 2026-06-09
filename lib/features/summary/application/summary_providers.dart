import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../feed/application/feed_providers.dart';
import '../../feed/data/models/reddit_comment.dart';
import '../../feed/data/models/reddit_post.dart';
import '../data/ai_summary.dart';
import '../data/gemini_service.dart';

/// Real Gemini when a key is configured, otherwise a labelled demo service.
final geminiServiceProvider = Provider<GeminiService>((ref) {
  if (Env.hasGemini) return GeminiServiceImpl();
  return const MockGeminiService();
});

/// Top comments for a post. Shared by the detail screen and the AI summary so
/// the thread is fetched only once per post.
final commentsProvider =
    FutureProvider.autoDispose.family<List<RedditComment>, RedditPost>(
  (ref, post) {
    return ref.watch(redditRepositoryProvider).fetchComments(
          subreddit: post.subreddit,
          postId: post.id,
        );
  },
);

/// Two-part Uzbek AI summary (post + discussion). Awaits [commentsProvider] so
/// it reuses the already-fetched comments. `ref.invalidate(summaryProvider(post))`
/// regenerates.
final summaryProvider =
    FutureProvider.autoDispose.family<AiSummary, RedditPost>((ref, post) async {
  // Reuse the shared comments; tolerate comment failures by summarising the
  // post alone rather than failing the whole summary.
  List<RedditComment> comments = const [];
  try {
    comments = await ref.watch(commentsProvider(post).future);
  } catch (_) {
    comments = const [];
  }
  // Read (not watch) after the await: in an autoDispose provider, watching a
  // dependency post-await risks acting on a disposed ref if the sheet closes
  // mid-fetch. The service never changes anyway.
  return ref.read(geminiServiceProvider).summarize(post, comments);
});

/// Whether real AI is active — drives a small "demo" badge in the UI.
final isRealAiProvider = Provider<bool>((ref) => Env.hasGemini);
