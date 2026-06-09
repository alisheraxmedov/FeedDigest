import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/env.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/application/auth_providers.dart';
import '../data/mock_reddit_repository.dart';
import '../data/reddit_repository.dart';
import '../data/reddit_repository_impl.dart';
import 'feed_state.dart';

/// Picks the live or mock Reddit source. Watches login state so that the whole
/// data layer rebuilds (and refetches) the moment the user logs in or out.
final redditRepositoryProvider = Provider<RedditRepository>((ref) {
  final loggedIn = ref.watch(isLoggedInProvider);
  if (loggedIn || Env.useRealReddit) {
    return RedditRepositoryImpl(tokenProvider: ref.read(redditTokenProvider));
  }
  return const MockRedditRepository();
});

/// Globally selected sort mode for the home feeds.
final feedSortProvider =
    NotifierProvider<FeedSortNotifier, FeedSort>(FeedSortNotifier.new);

class FeedSortNotifier extends Notifier<FeedSort> {
  @override
  FeedSort build() => FeedSort.hot;

  void set(FeedSort sort) => state = sort;
}

/// One feed per (subreddit, sort). Auto-disposed when its tab is no longer
/// watched to keep memory bounded as the user switches topics.
final feedProvider = AsyncNotifierProvider.autoDispose
    .family<FeedNotifier, FeedState, FeedQuery>(FeedNotifier.new);

class FeedNotifier extends AsyncNotifier<FeedState> {
  FeedNotifier(this.query);

  final FeedQuery query;

  RedditRepository get _repo => ref.read(redditRepositoryProvider);

  @override
  Future<FeedState> build() async {
    // Watch (not read) so the feed refetches when the repository swaps on
    // login/logout.
    final repo = ref.watch(redditRepositoryProvider);
    final page = await repo.fetchFeed(
      subreddit: query.subreddit,
      sort: query.sort,
    );
    return FeedState(posts: page.posts, after: page.after);
  }

  /// Appends the next page. No-op while already loading or when exhausted.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, clearError: true));
    try {
      final page = await _repo.fetchFeed(
        subreddit: query.subreddit,
        sort: query.sort,
        after: current.after,
      );
      state = AsyncData(FeedState(
        posts: [...current.posts, ...page.posts],
        after: page.after,
        isLoadingMore: false,
      ));
    } on ApiException catch (e) {
      state = AsyncData(current.copyWith(
        isLoadingMore: false,
        loadMoreError: e.message,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(
        isLoadingMore: false,
        loadMoreError: 'Qo‘shimcha postlarni yuklab bo‘lmadi.',
      ));
    }
  }

  /// Pull-to-refresh: rebuild from the first page.
  Future<void> refresh() => ref.refresh(feedProvider(query).future);
}
