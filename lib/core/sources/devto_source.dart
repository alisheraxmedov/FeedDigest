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
          FeedSort sort = FeedSort.newest}) =>
      _fetch(topic, limit, sort);

  @override
  Future<List<Article>> search(String query,
          {int limit = AppConfig.searchLimit}) =>
      _fetch(query, limit, FeedSort.popular);

  Future<List<Article>> _fetch(String tag, int limit, FeedSort sort) async {
    // Without `top` the Forem API returns the most recently published
    // articles; with `top=<days>` it returns the highest rated of that window.
    final params = {
      'tag': tag.toLowerCase(),
      'per_page': '$limit',
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
