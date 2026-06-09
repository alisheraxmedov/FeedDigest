import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/env.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/data/reddit_user_session.dart';
import 'models/reddit_comment.dart';
import 'models/reddit_page.dart';
import 'models/subreddit.dart';
import 'reddit_repository.dart';

/// Live Reddit data source.
///
/// Uses the authenticated `oauth.reddit.com` host when a client id is present
/// (higher rate limits, fewer blocks), and falls back to the public
/// `www.reddit.com/*.json` endpoints otherwise. All requests carry a
/// descriptive User-Agent and `raw_json=1` to avoid HTML-escaped URLs.
class RedditRepositoryImpl implements RedditRepository {
  RedditRepositoryImpl({required RedditTokenProvider tokenProvider, Dio? dio})
      : _tokenProvider = tokenProvider,
        _dio = dio ?? DioClient.create();

  final Dio _dio;
  final RedditTokenProvider _tokenProvider;

  @override
  Future<RedditPage> fetchFeed({
    required String subreddit,
    required FeedSort sort,
    String? after,
  }) async {
    final json = await _request(
      '/r/$subreddit/${sort.value}',
      query: {
        'limit': AppConfig.pageSize,
        'after': ?after,
        // `top`/`rising` accept a time window — default to the past week.
        if (sort == FeedSort.top) 't': 'week',
      },
    );
    return RedditPage.fromListing(_asMap(json));
  }

  @override
  Future<RedditPage> search({
    required String query,
    String? subreddit,
    String? after,
  }) async {
    final path =
        subreddit == null ? '/search' : '/r/$subreddit/search';
    final json = await _request(
      path,
      query: {
        'q': query,
        'type': 'link',
        'sort': 'relevance',
        'limit': AppConfig.pageSize,
        if (subreddit != null) 'restrict_sr': 1,
        'after': ?after,
      },
    );
    return RedditPage.fromListing(_asMap(json));
  }

  @override
  Future<List<RedditComment>> fetchComments({
    required String subreddit,
    required String postId,
    int limit = 12,
  }) async {
    final json = await _request(
      '/r/$subreddit/comments/$postId',
      query: {
        'sort': 'top',
        'limit': limit,
        'depth': 1,
      },
    );
    return RedditComment.fromThread(json, limit: limit);
  }

  @override
  Future<RedditPage> fetchHomeFeed({
    required FeedSort sort,
    String? after,
  }) async {
    // Authenticated root listing == the user's subscribed front page.
    final json = await _request(
      '/${sort.value}',
      query: {
        'limit': AppConfig.pageSize,
        'after': ?after,
        if (sort == FeedSort.top) 't': 'week',
      },
    );
    return RedditPage.fromListing(_asMap(json));
  }

  @override
  Future<List<Subreddit>> fetchMySubreddits() async {
    final all = <Subreddit>[];
    String? after;
    // Page through every subscription. The cap is a safety net against a
    // malformed `after` cursor looping forever (20 × 100 = 2000 subreddits).
    for (var page = 0; page < 20; page++) {
      final json = await _request(
        '/subreddits/mine/subscriber',
        query: {'limit': 100, 'after': ?after},
      );
      all.addAll(Subreddit.fromListing(json));
      after = _listingAfter(json);
      if (after == null || after.isEmpty) break;
    }
    return all;
  }

  String? _listingAfter(dynamic json) {
    if (json is Map && json['data'] is Map) {
      final after = (json['data'] as Map)['after'];
      return after is String ? after : null;
    }
    return null;
  }

  @override
  Future<void> setSubscribed({
    required String subreddit,
    required bool subscribe,
  }) {
    return _postForm('/api/subscribe', {
      'action': subscribe ? 'sub' : 'unsub',
      'sr_name': subreddit,
      'api_type': 'json',
    });
  }

  @override
  Future<void> vote({required String fullname, required int dir}) {
    return _postForm('/api/vote', {'id': fullname, 'dir': dir});
  }

  // --- Internals ------------------------------------------------------------

  Map<String, dynamic> _asMap(dynamic json) {
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return Map<String, dynamic>.from(json);
    throw const ApiException('Reddit kutilmagan javob qaytardi.');
  }

  Future<dynamic> _request(
    String path, {
    required Map<String, dynamic> query,
  }) async {
    final token = await _tokenProvider.bearerToken();
    final headers = <String, dynamic>{'User-Agent': Env.redditUserAgent};
    final String url;

    if (token != null) {
      // Authenticated host (user token when logged in, else app-only).
      headers['Authorization'] = 'Bearer $token';
      url = '${AppConfig.redditOAuthBase}$path';
    } else {
      // Public host requires the `.json` suffix.
      url = '${AppConfig.redditPublicBase}$path.json';
    }

    try {
      final response = await _dio.get<dynamic>(
        url,
        queryParameters: {...query, 'raw_json': 1},
        options: Options(headers: headers),
      );

      final status = response.statusCode ?? 0;
      if (status != 200) throw _mapStatus(status);

      // The decoded body is a Map for listings/search and a List for the
      // comments thread; callers parse the shape they expect.
      return response.data;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw _mapStatus(e.response?.statusCode ?? 0, dio: e);
    }
  }

  /// Authenticated form POST (subscribe / vote). Requires a user token.
  Future<void> _postForm(String path, Map<String, dynamic> body) async {
    final token = await _tokenProvider.bearerToken();
    if (token == null || !_tokenProvider.isUserAuthenticated) {
      throw const ApiException(
        'Bu amal uchun Reddit hisobiga kirish kerak.',
        statusCode: 401,
      );
    }
    try {
      final response = await _dio.post<dynamic>(
        '${AppConfig.redditOAuthBase}$path',
        data: body,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Authorization': 'Bearer $token',
            'User-Agent': Env.redditUserAgent,
          },
        ),
      );
      final status = response.statusCode ?? 0;
      if (status != 200) throw _mapStatus(status);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw _mapStatus(e.response?.statusCode ?? 0, dio: e);
    }
  }

  ApiException _mapStatus(int status, {DioException? dio}) {
    switch (status) {
      case 403:
        return const ApiException(
          'Reddit ulanishni rad etdi (403). OAuth kalit qo‘shing yoki '
          'keyinroq urinib ko‘ring.',
          statusCode: 403,
        );
      case 404:
        return const ApiException(
          'Subreddit topilmadi yoki mavjud emas (404).',
          statusCode: 404,
        );
      case 429:
        return const ApiException(
          'Juda ko‘p so‘rov yuborildi (429). Birozdan so‘ng urinib ko‘ring.',
          statusCode: 429,
        );
      default:
        if (dio?.type == DioExceptionType.connectionTimeout ||
            dio?.type == DioExceptionType.receiveTimeout) {
          return const ApiException('Ulanish vaqti tugadi. Internetni '
              'tekshiring va qayta urining.');
        }
        return ApiException(
          'Reddit bilan bog‘lanishda xatolik yuz berdi'
          '${status > 0 ? ' ($status)' : ''}.',
          statusCode: status,
        );
    }
  }
}
