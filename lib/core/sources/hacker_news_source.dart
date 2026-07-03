/*
Hacker News source — backed by the Algolia search API.
Endpoint: https://hn.algolia.com/api/v1/search?query=<topic>&tags=story
No auth, API key or registration required.
Each "hit" in the response is mapped to an Article; id is "hn-<objectID>".
When a story has no url (e.g. Ask HN), its discussion (item) page is used as the link.
*/
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../utils/readable_page.dart';
import '../../models/article.dart';
import 'article_source.dart';

class HackerNewsSource implements ArticleSource {
  HackerNewsSource(this._dio);

  final Dio _dio;

  @override
  FeedSource get kind => FeedSource.hackerNews;

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
  }) => _fetch(query, limit, 1, FeedSort.popular);

  // The Algolia API carries `story_text` only for text posts (Ask/Show HN);
  // link submissions — the bulk of the feed — have no body at all. For those we
  // fetch the linked page and extract its readable text so the reader and AI
  // summary have real content. Failures fall back to the (empty) feed body.
  @override
  Future<String> fullBody(Article article) async {
    if (article.body.trim().isNotEmpty) return article.body;
    if (article.url.contains('news.ycombinator.com')) return '';
    return fetchReadablePage(_dio, article.url);
  }

  Future<List<Article>> _fetch(
    String query,
    int limit,
    int page,
    FeedSort sort,
  ) async {
    // search_by_date returns the most recent stories first; search ranks by
    // relevance/popularity. Algolia pages are 0-indexed.
    final path = sort == FeedSort.newest
        ? '/api/v1/search_by_date'
        : '/api/v1/search';
    final resp = await _dio.getUri<dynamic>(
      Uri.https(AppConfig.hackerNewsHost, path, {
        'query': query,
        'tags': 'story',
        'hitsPerPage': '$limit',
        'page': '${page < 1 ? 0 : page - 1}',
      }),
      options: Options(responseType: ResponseType.json),
    );
    return parse(resp.data, query);
  }

  static List<Article> parse(dynamic data, String topic) {
    final hits = (data is Map ? data['hits'] as List? : null) ?? const [];
    return hits
        .whereType<Map>()
        .map((hit) => _toArticle(Map<String, dynamic>.from(hit), topic))
        .where((article) => article.id.isNotEmpty && article.title.isNotEmpty)
        .toList();
  }

  static Article _toArticle(Map<String, dynamic> hit, String topic) {
    final objectId = hit['objectID']?.toString() ?? '';
    final url = hit['url'] as String? ?? '';
    final commentsUrl = objectId.isEmpty
        ? ''
        : 'https://news.ycombinator.com/item?id=$objectId';
    final createdAt = (hit['created_at_i'] as num?)?.toInt() ?? 0;
    return Article(
      id: objectId.isEmpty ? '' : 'hn-$objectId',
      title: (hit['title'] as String?) ?? (hit['story_title'] as String?) ?? '',
      body: hit['story_text'] as String? ?? '',
      url: url.isNotEmpty ? url : commentsUrl,
      commentsUrl: commentsUrl,
      author: hit['author'] as String? ?? '',
      topic: topic,
      source: FeedSource.hackerNews.label,
      score: (hit['points'] as num?)?.toInt() ?? 0,
      commentCount: (hit['num_comments'] as num?)?.toInt() ?? 0,
      publishedAt: DateTime.fromMillisecondsSinceEpoch(
        createdAt * 1000,
        isUtc: true,
      ),
      imageUrl: '',
    );
  }
}
