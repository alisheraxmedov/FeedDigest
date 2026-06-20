import '../core/config/app_config.dart';
import '../core/network/reddit_client.dart';
import '../models/reddit_post.dart';
import '../models/subreddit.dart';

class RedditRepository {
  RedditRepository(this._client);

  final RedditClient _client;

  Future<List<RedditPost>> topPosts(
    String subreddit, {
    String time = AppConfig.topPeriod,
    int limit = AppConfig.feedLimit,
  }) async {
    final data = await _client.getJson('/r/$subreddit/top.json', {
      't': time,
      'limit': limit,
    });
    return _parse(data);
  }

  Future<List<RedditPost>> searchPosts(
    String query, {
    String? subreddit,
    String sort = 'top',
    String time = 'month',
    int limit = AppConfig.searchLimit,
  }) async {
    final path =
        subreddit == null ? '/search.json' : '/r/$subreddit/search.json';
    final data = await _client.getJson(path, {
      'q': query,
      'sort': sort,
      't': time,
      'limit': limit,
      'type': 'link',
      if (subreddit != null) 'restrict_sr': 'true',
    });
    return _parse(data);
  }

  Future<List<Subreddit>> searchSubreddits(
    String query, {
    int limit = AppConfig.searchLimit,
  }) async {
    final data = await _client.getJson('/subreddits/search.json', {
      'q': query,
      'limit': limit,
    });
    return _parseSubreddits(data);
  }

  List<RedditPost> _parse(dynamic data) {
    final listing = data is List ? data.first : data;
    final children = (listing['data']?['children'] as List?) ?? const [];
    return children
        .where((c) => c is Map && c['kind'] == 't3' && c['data'] is Map)
        .map((c) => RedditPost.fromJson(Map<String, dynamic>.from(c['data'])))
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  List<Subreddit> _parseSubreddits(dynamic data) {
    final listing = data is List ? data.first : data;
    final children = (listing['data']?['children'] as List?) ?? const [];
    return children
        .where((c) => c is Map && c['kind'] == 't5' && c['data'] is Map)
        .map((c) => Subreddit.fromJson(Map<String, dynamic>.from(c['data'])))
        .where((s) => s.name.isNotEmpty)
        .toList();
  }
}
