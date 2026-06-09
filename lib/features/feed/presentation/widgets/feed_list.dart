import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/state_views.dart';
import '../../application/feed_providers.dart';
import '../../application/feed_state.dart';
import '../../application/home_feed_providers.dart';
import 'post_card.dart';
import 'post_skeleton.dart';

/// Presentation-only feed renderer: pull-to-refresh, skeleton loading,
/// infinite scroll and inline errors. Bound to a provider by the thin
/// [FeedList] / [HomeFeedList] wrappers below.
class FeedListView extends StatelessWidget {
  const FeedListView({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onRetry,
  });

  final AsyncValue<FeedState> state;
  final Future<void> Function() onRefresh;
  final void Function() onLoadMore;
  final void Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const PostSkeletonList(),
      error: (error, _) => AppErrorView(
        message: _messageFor(error),
        onRetry: onRetry,
      ),
      data: (feed) => _Loaded(
        state: feed,
        onRefresh: onRefresh,
        onLoadMore: onLoadMore,
      ),
    );
  }

  static String _messageFor(Object error) {
    final msg = error.toString();
    final idx = msg.indexOf(': ');
    return idx >= 0 ? msg.substring(idx + 2) : msg;
  }
}

/// One subreddit feed (subreddit + sort).
class FeedList extends ConsumerWidget {
  const FeedList({super.key, required this.query});

  final FeedQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeedListView(
      state: ref.watch(feedProvider(query)),
      onRefresh: () => ref.refresh(feedProvider(query).future),
      onLoadMore: () => ref.read(feedProvider(query).notifier).loadMore(),
      onRetry: () => ref.invalidate(feedProvider(query)),
    );
  }
}

/// The logged-in user's home (subscriptions) feed.
class HomeFeedList extends ConsumerWidget {
  const HomeFeedList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeedListView(
      state: ref.watch(homeFeedProvider),
      onRefresh: () => ref.refresh(homeFeedProvider.future),
      onLoadMore: () => ref.read(homeFeedProvider.notifier).loadMore(),
      onRetry: () => ref.invalidate(homeFeedProvider),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
  });

  final FeedState state;
  final Future<void> Function() onRefresh;
  final void Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state.posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            AppEmptyView(
              icon: Icons.forum_outlined,
              title: 'Postlar topilmadi',
              message: 'Bu yerda hozircha post yo‘q. '
                  'Pastga torting yoki boshqa mavzuni tanlang.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 400) {
            onLoadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: state.posts.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == state.posts.length) {
              return _Footer(state: state, onLoadMore: onLoadMore);
            }
            return PostCard(post: state.posts[index]);
          },
        ),
      ),
    );
  }
}

/// Bottom-of-list status: loading spinner, retry-on-error, or end marker.
class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onLoadMore});

  final FeedState state;
  final void Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }

    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              state.loadMoreError!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onLoadMore,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Qayta urinish'),
            ),
          ],
        ),
      );
    }

    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            '· Hammasi shu ·',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
      );
    }

    return const SizedBox(height: 24);
  }
}
