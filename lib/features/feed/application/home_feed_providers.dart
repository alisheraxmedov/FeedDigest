import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'feed_providers.dart';
import 'feed_state.dart';

/// The logged-in user's personalized front page (subscriptions combined),
/// reacting to the global sort selection.
final homeFeedProvider =
    AsyncNotifierProvider.autoDispose<HomeFeedNotifier, FeedState>(
        HomeFeedNotifier.new);

class HomeFeedNotifier extends AsyncNotifier<FeedState> {
  @override
  Future<FeedState> build() async {
    final repo = ref.watch(redditRepositoryProvider);
    final sort = ref.watch(feedSortProvider);
    final page = await repo.fetchHomeFeed(sort: sort);
    return FeedState(posts: page.posts, after: page.after);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, clearError: true));
    try {
      final page = await ref.read(redditRepositoryProvider).fetchHomeFeed(
            sort: ref.read(feedSortProvider),
            after: current.after,
          );
      state = AsyncData(FeedState(
        posts: [...current.posts, ...page.posts],
        after: page.after,
        isLoadingMore: false,
      ));
    } on ApiException catch (e) {
      state = AsyncData(
          current.copyWith(isLoadingMore: false, loadMoreError: e.message));
    } catch (_) {
      state = AsyncData(current.copyWith(
        isLoadingMore: false,
        loadMoreError: 'Qo‘shimcha postlarni yuklab bo‘lmadi.',
      ));
    }
  }
}
