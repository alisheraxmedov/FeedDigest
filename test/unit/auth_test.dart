import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/core/network/dio_client.dart';
import 'package:feeddigest/features/auth/data/oauth_config.dart';
import 'package:feeddigest/features/auth/data/reddit_oauth_service.dart';

void main() {
  group('OAuthConfig', () {
    test('buildAuthUrl includes the required OAuth params', () {
      final url = OAuthConfig.buildAuthUrl(clientId: 'abc123', state: 'xyz');
      final uri = Uri.parse(url);
      expect(uri.queryParameters['client_id'], 'abc123');
      expect(uri.queryParameters['response_type'], 'code');
      expect(uri.queryParameters['state'], 'xyz');
      expect(uri.queryParameters['redirect_uri'], OAuthConfig.redirectUri);
      expect(uri.queryParameters['duration'], 'permanent');
      expect(uri.queryParameters['scope'], contains('vote'));
      expect(uri.queryParameters['scope'], contains('subscribe'));
      expect(uri.queryParameters['scope'], contains('mysubreddits'));
    });

    test('generateState produces distinct, non-empty values', () {
      final a = OAuthConfig.generateState();
      final b = OAuthConfig.generateState();
      expect(a, isNotEmpty);
      expect(a, isNot(equals(b)));
    });
  });

  group('RedditTokenResponse.fromJson', () {
    test('parses access, refresh and expiry', () {
      final t = RedditTokenResponse.fromJson({
        'access_token': 'AT',
        'refresh_token': 'RT',
        'expires_in': 3600,
      });
      expect(t.accessToken, 'AT');
      expect(t.refreshToken, 'RT');
      expect(t.expiresIn, 3600);
    });

    test('defaults expiry and tolerates a missing refresh token', () {
      final t = RedditTokenResponse.fromJson({'access_token': 'AT'});
      expect(t.expiresIn, 3600);
      expect(t.refreshToken, isNull);
    });

    test('throws when access_token is missing', () {
      expect(
        () => RedditTokenResponse.fromJson({'expires_in': 10}),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
