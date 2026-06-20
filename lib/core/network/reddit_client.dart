import 'package:dio/dio.dart';
import '../config/app_config.dart';

class RedditException implements Exception {
  RedditException(this.message);
  final String message;
  @override
  String toString() => 'RedditException: $message';
}

class RedditClient {
  RedditClient(this._dio);

  final Dio _dio;

  Future<dynamic> getJson(
    String path,
    Map<String, dynamic> queryParameters,
  ) async {
    Object? lastError;
    for (final host in AppConfig.redditHosts) {
      try {
        final uri = Uri.https(host, path, _stringify(queryParameters));
        final resp = await _dio.getUri<dynamic>(
          uri,
          options: Options(
            headers: {'User-Agent': AppConfig.userAgent},
            responseType: ResponseType.json,
          ),
        );
        if (resp.data != null) return resp.data;
        lastError = RedditException('Empty response from $host');
      } catch (e) {
        lastError = e;
      }
    }
    throw RedditException('All Reddit hosts failed: $lastError');
  }

  Map<String, String> _stringify(Map<String, dynamic> params) =>
      params.map((key, value) => MapEntry(key, '$value'));
}
