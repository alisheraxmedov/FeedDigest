import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/env.dart';
import '../../../core/network/dio_client.dart';

/// Obtains and caches a Reddit OAuth token using the **installed_client**
/// grant, which is the correct flow for a shipped mobile app — it needs only a
/// `client_id` (no secret, username or password).
///
/// Tokens are valid for ~1 hour; we refresh a minute early.
class RedditAuth {
  RedditAuth({Dio? dio}) : _dio = dio ?? DioClient.create();

  final Dio _dio;

  String? _token;
  DateTime? _expiresAt;

  bool get _isValid =>
      _token != null &&
      _expiresAt != null &&
      DateTime.now().isBefore(_expiresAt!);

  /// Returns a cached token when still valid, otherwise requests a new one.
  Future<String> token() async {
    if (_isValid) return _token!;

    final clientId = Env.redditClientId;
    if (clientId.isEmpty) {
      throw const ApiException('Reddit client id sozlanmagan.');
    }

    // Basic auth: "<client_id>:" (installed apps have no secret).
    final basic = base64Encode(utf8.encode('$clientId:'));

    final response = await _dio.post<Map<String, dynamic>>(
      AppConfig.redditTokenUrl,
      data: {
        'grant_type':
            'https://oauth.reddit.com/grants/installed_client',
        'device_id': 'DO_NOT_TRACK_THIS_DEVICE',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {
          'Authorization': 'Basic $basic',
          'User-Agent': Env.redditUserAgent,
        },
      ),
    );

    final data = response.data;
    final accessToken = data?['access_token'];
    if (response.statusCode != 200 || accessToken is! String) {
      throw ApiException(
        'Reddit autentifikatsiyasi muvaffaqiyatsiz (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    final expiresIn = (data?['expires_in'] as num?)?.toInt() ?? 3600;
    _token = accessToken;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn - 60));
    return accessToken;
  }
}
