import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/env.dart';
import '../../../core/network/dio_client.dart';
import 'oauth_config.dart';

/// Parsed token endpoint response.
class RedditTokenResponse {
  const RedditTokenResponse({
    required this.accessToken,
    required this.expiresIn,
    this.refreshToken,
  });

  final String accessToken;
  final int expiresIn;

  /// Present on the initial code exchange; refresh responses may omit it, in
  /// which case the previously stored refresh token stays valid.
  final String? refreshToken;

  factory RedditTokenResponse.fromJson(Map<String, dynamic> json) {
    final token = json['access_token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('Reddit token javobida access_token yo‘q.');
    }
    return RedditTokenResponse(
      accessToken: token,
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
      refreshToken: json['refresh_token'] as String?,
    );
  }
}

/// Result of a successful interactive login.
class RedditAuthResult {
  const RedditAuthResult({required this.token, required this.username});

  final RedditTokenResponse token;
  final String username;
}

/// Performs the interactive Reddit OAuth login and raw token endpoint calls.
///
/// Access-token caching, expiry and single-flight refresh live in the session /
/// token provider, not here — this class only does discrete network steps.
class RedditOAuthService {
  RedditOAuthService({Dio? dio}) : _dio = dio ?? DioClient.create();

  final Dio _dio;

  /// Opens the browser, lets the user authorize, and exchanges the returned
  /// code for tokens. Verifies the CSRF `state` round-trip.
  Future<RedditAuthResult> login() async {
    final clientId = Env.redditClientId;
    if (clientId.isEmpty) {
      throw const ApiException(
        'Reddit client id sozlanmagan. `.env` ga REDDIT_CLIENT_ID qo‘shing.',
      );
    }

    final state = OAuthConfig.generateState();
    final authUrl = OAuthConfig.buildAuthUrl(clientId: clientId, state: state);

    final callback = await FlutterWebAuth2.authenticate(
      url: authUrl,
      callbackUrlScheme: OAuthConfig.callbackScheme,
    );

    final returned = Uri.parse(callback);
    final error = returned.queryParameters['error'];
    if (error != null) {
      throw ApiException('Reddit ruxsat bermadi: $error');
    }
    if (returned.queryParameters['state'] != state) {
      throw const ApiException('Xavfsizlik xatosi: state mos kelmadi.');
    }
    final code = returned.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw const ApiException('Avtorizatsiya kodi olinmadi.');
    }

    final token = await exchangeCode(code, clientId);
    final username = await fetchUsername(token.accessToken);
    return RedditAuthResult(token: token, username: username);
  }

  Future<RedditTokenResponse> exchangeCode(String code, String clientId) {
    return _postToken(clientId, {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': OAuthConfig.redirectUri,
    });
  }

  Future<RedditTokenResponse> refresh(String refreshToken, String clientId) {
    return _postToken(clientId, {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    });
  }

  Future<String> fetchUsername(String accessToken) async {
    final response = await _dio.get<dynamic>(
      '${AppConfig.redditOAuthBase}/api/v1/me',
      options: Options(headers: {
        'Authorization': 'Bearer $accessToken',
        'User-Agent': Env.redditUserAgent,
      }),
    );
    final data = response.data;
    final name = data is Map ? data['name'] : null;
    if (response.statusCode != 200 || name is! String) {
      throw const ApiException('Foydalanuvchi ma‘lumotini olishda xatolik.');
    }
    return name;
  }

  Future<RedditTokenResponse> _postToken(
    String clientId,
    Map<String, dynamic> body,
  ) async {
    final basic = base64Encode(utf8.encode('$clientId:'));
    try {
      final response = await _dio.post<dynamic>(
        OAuthConfig.tokenUrl,
        data: body,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Authorization': 'Basic $basic',
            'User-Agent': Env.redditUserAgent,
          },
        ),
      );
      if (response.statusCode != 200 || response.data is! Map) {
        throw ApiException(
          'Reddit token almashinuvi muvaffaqiyatsiz (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
      return RedditTokenResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(
        'Reddit token almashinuvida xatolik: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
