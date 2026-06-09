import '../../../core/config/app_config.dart';
import 'models/reddit_comment.dart';
import 'models/reddit_page.dart';
import 'models/subreddit.dart';

/// Abstraction over the Reddit data source.
///
/// Two implementations exist behind this interface: a live one
/// ([RedditRepositoryImpl]) and a [MockRedditRepository] used when no
/// credentials are configured, so the whole app is demoable offline.
abstract interface class RedditRepository {
  /// Fetches a page of posts for [subreddit] ordered by [sort].
  Future<RedditPage> fetchFeed({
    required String subreddit,
    required FeedSort sort,
    String? after,
  });

  /// Searches Reddit for [query], optionally restricted to [subreddit].
  Future<RedditPage> search({
    required String query,
    String? subreddit,
    String? after,
  });

  /// Fetches the top-level comments for a post (best/top, capped).
  Future<List<RedditComment>> fetchComments({
    required String subreddit,
    required String postId,
    int limit,
  });

  // --- Authenticated (logged-in) operations ---------------------------------

  /// The logged-in user's personalized front page (their subscriptions
  /// combined), ordered by [sort].
  Future<RedditPage> fetchHomeFeed({
    required FeedSort sort,
    String? after,
  });

  /// The subreddits the logged-in user is subscribed to.
  Future<List<Subreddit>> fetchMySubreddits();

  /// Subscribes to or unsubscribes from [subreddit].
  Future<void> setSubscribed({
    required String subreddit,
    required bool subscribe,
  });

  /// Casts a vote on a thing (`t3_<id>`): dir 1 = up, -1 = down, 0 = clear.
  Future<void> vote({required String fullname, required int dir});
}
