/*
Lobsters source — backed by the open lobste.rs JSON API (no auth, no key).
Lobsters has a fixed tag vocabulary and no JSON search endpoint, so:
  - a topic that is a real tag (rust, go, ai, security, …) uses /t/<tag>.json;
  - any other topic (e.g. "flutter") filters the general /hottest|/newest feed by
    keyword — with no fallback to unrelated stories, so an uncovered topic yields
    few/no items rather than misleading general news.
Each story maps to an Article ("lobsters-<short_id>"); link posts fetch their
readable body on demand (like Hacker News).
*/
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../utils/readable_page.dart';
import '../utils/topic_filter.dart';
import '../../models/article.dart';
import 'article_source.dart';

class LobstersSource implements ArticleSource {
  LobstersSource(this._dio);

  final Dio _dio;

  @override
  FeedSource get kind => FeedSource.lobsters;

  @override
  Future<List<Article>> topPosts(
    String topic, {
    int limit = AppConfig.feedLimit,
    int page = 1,
    FeedSort sort = FeedSort.newest,
  }) => _fetch(topic, limit, page, sort);

  @override
  Future<List<Article>> search(
    String query, {
    int limit = AppConfig.searchLimit,
  }) async {
    // Lobsters has no usable JSON search endpoint (/search.json 400s), so match
    // the query against the general feed client-side.
    final pool = await _general(page: 1, sort: FeedSort.newest);
    return filterArticlesByTopic(pool, query).take(limit).toList();
  }

  @override
  Future<String> fullBody(Article article) async {
    final url = article.url;
    final isExternal = url.startsWith('http') && !url.contains('lobste.rs');
    if (!isExternal) return article.body;
    final extracted = await fetchReadablePage(_dio, url);
    return extracted.isNotEmpty ? extracted : article.body;
  }

  Future<List<Article>> _fetch(
    String topic,
    int limit,
    int page,
    FeedSort sort,
  ) async {
    final tag = topic.trim().toLowerCase();
    if (tag.isEmpty) {
      final list = await _general(page: page, sort: sort);
      return list.take(limit).toList();
    }
    // A real tag has its own feed; an unknown tag 404s.
    try {
      final tagged = await _getStories(
        Uri.https(
          AppConfig.lobstersHost,
          '/t/$tag.json',
          page > 1 ? {'page': '$page'} : null,
        ),
        topic,
      );
      if (tagged.isNotEmpty) return tagged.take(limit).toList();
    } on DioException {
      // Unknown tag — fall through to a keyword filter of the general feed.
    }
    final pool = await _general(page: 1, sort: sort);
    return filterArticlesByTopic(pool, topic).take(limit).toList();
  }

  Future<List<Article>> _general({required int page, required FeedSort sort}) {
    final path = sort == FeedSort.popular ? '/hottest.json' : '/newest.json';
    return _getStories(
      Uri.https(AppConfig.lobstersHost, path, page > 1 ? {'page': '$page'} : null),
      '',
    );
  }

  Future<List<Article>> _getStories(Uri uri, String topic) async {
    final resp = await _dio.getUri<dynamic>(
      uri,
      options: Options(responseType: ResponseType.json),
    );
    return parse(resp.data, topic);
  }

  static List<Article> parse(dynamic data, String topic) {
    final list = data is List
        ? data
        : (data is Map ? (data['stories'] as List? ?? const []) : const []);
    return list
        .whereType<Map>()
        .map((story) => _toArticle(Map<String, dynamic>.from(story), topic))
        .where((article) => article.id.isNotEmpty && article.title.isNotEmpty)
        .toList();
  }

  static Article _toArticle(Map<String, dynamic> story, String topic) {
    final shortId = story['short_id']?.toString() ?? '';
    final submitter = story['submitter_user'];
    final author = submitter is Map
        ? (submitter['username'] as String? ?? '')
        : (submitter as String? ?? '');
    final url = story['url'] as String? ?? '';
    final commentsUrl =
        (story['comments_url'] as String?) ?? (story['short_id_url'] as String?) ?? '';
    final tags = (story['tags'] as List?)?.whereType<String>().toList() ?? const <String>[];
    return Article(
      id: shortId.isEmpty ? '' : 'lobsters-$shortId',
      title: story['title'] as String? ?? '',
      body: (story['description_plain'] as String? ?? '').trim(),
      url: url.isNotEmpty ? url : commentsUrl,
      commentsUrl: commentsUrl,
      author: author,
      topic: topic.trim().isNotEmpty ? topic : (tags.isNotEmpty ? tags.first : ''),
      source: FeedSource.lobsters.label,
      score: (story['score'] as num?)?.toInt() ?? 0,
      commentCount: (story['comment_count'] as num?)?.toInt() ?? 0,
      publishedAt:
          DateTime.tryParse(story['created_at'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      imageUrl: '',
    );
  }
}
