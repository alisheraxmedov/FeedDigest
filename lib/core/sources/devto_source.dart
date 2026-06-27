/*
dev.to source — backed by the open Forem API.
Endpoint: https://dev.to/api/articles?tag=<topic>&top=<days>&per_page=<n>
No auth, API key or registration required.
The topic is used as a tag (lower-cased).
Each article is mapped to an Article; id is "devto-<id>".
*/
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../../models/article.dart';
import 'article_source.dart';

class DevtoSource implements ArticleSource {
  DevtoSource(this._dio);

  final Dio _dio;

  @override
  FeedSource get kind => FeedSource.devto;

  @override
  Future<List<Article>> topPosts(String topic,
          {int limit = AppConfig.feedLimit,
          int page = 1,
          FeedSort sort = FeedSort.newest}) =>
      _fetch(topic, limit, page, sort);

  @override
  Future<List<Article>> search(String query,
          {int limit = AppConfig.searchLimit}) =>
      _fetch(query, limit, 1, FeedSort.popular);

  /// Fetches the complete article body via the single-article endpoint
  /// (`/api/articles/{id}`). The list endpoint only carries a short
  /// `description`; this returns the full `body_markdown`, or '' if missing.
  /// [articleId] is the namespaced id (e.g. `devto-12345`).
  Future<String> fetchFullBody(String articleId) async {
    final numId =
        articleId.startsWith('devto-') ? articleId.substring(6) : articleId;
    if (numId.isEmpty) return '';
    final resp = await _dio.getUri<dynamic>(
      Uri.https(AppConfig.devtoHost, '/api/articles/$numId'),
      options: Options(responseType: ResponseType.json),
    );
    final data = resp.data;
    if (data is Map) {
      return (data['body_markdown'] as String?)?.trim() ?? '';
    }
    return '';
  }

  Future<List<Article>> _fetch(
      String tag, int limit, int page, FeedSort sort) async {
    // Without `top` the Forem API returns the most recently published
    // articles; with `top=<days>` it returns the highest rated of that window.
    // Forem pages are 1-indexed.
    final params = {
      'tag': tag.toLowerCase(),
      'per_page': '$limit',
      'page': '${page < 1 ? 1 : page}',
      if (sort == FeedSort.popular) 'top': '${AppConfig.devtoTopDays}',
    };
    final resp = await _dio.getUri<dynamic>(
      Uri.https(AppConfig.devtoHost, '/api/articles', params),
      options: Options(responseType: ResponseType.json),
    );
    return parse(resp.data, tag);
  }

  static List<Article> parse(dynamic data, String topic) {
    final list = data is List ? data : const [];
    return list
        .whereType<Map>()
        .map((item) => _toArticle(Map<String, dynamic>.from(item), topic))
        .where((article) => article.id.isNotEmpty && article.title.isNotEmpty)
        .toList();
  }

  static Article _toArticle(Map<String, dynamic> item, String topic) {
    final id = item['id']?.toString() ?? '';
    final user = item['user'] is Map
        ? Map<String, dynamic>.from(item['user'] as Map)
        : const <String, dynamic>{};
    final cover = item['cover_image'] as String? ?? '';
    final social = item['social_image'] as String? ?? '';
    final url = item['url'] as String? ?? '';
    return Article(
      id: id.isEmpty ? '' : 'devto-$id',
      title: item['title'] as String? ?? '',
      body: item['description'] as String? ?? '',
      url: url,
      commentsUrl: url,
      author:
          (user['name'] as String?) ?? (user['username'] as String?) ?? '',
      topic: topic,
      source: FeedSource.devto.label,
      score: (item['positive_reactions_count'] as num?)?.toInt() ?? 0,
      commentCount: (item['comments_count'] as num?)?.toInt() ?? 0,
      publishedAt:
          DateTime.tryParse(item['published_at'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      imageUrl: cover.isNotEmpty ? cover : social,
    );
  }
}
