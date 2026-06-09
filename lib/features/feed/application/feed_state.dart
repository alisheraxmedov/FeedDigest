import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../data/models/reddit_post.dart';

/// Identifies a unique feed (subreddit + sort). Used as the family argument,
/// so value equality is essential for provider caching.
@immutable
class FeedQuery {
  const FeedQuery({required this.subreddit, required this.sort});

  final String subreddit;
  final FeedSort sort;

  @override
  bool operator ==(Object other) =>
      other is FeedQuery &&
      other.subreddit.toLowerCase() == subreddit.toLowerCase() &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(subreddit.toLowerCase(), sort);
}

/// The loaded state of a feed, including pagination bookkeeping.
@immutable
class FeedState {
  const FeedState({
    required this.posts,
    this.after,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<RedditPost> posts;
  final String? after;
  final bool isLoadingMore;
  final String? loadMoreError;

  bool get hasMore => after != null && after!.isNotEmpty;

  FeedState copyWith({
    List<RedditPost>? posts,
    String? after,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearError = false,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      after: after ?? this.after,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }
}
