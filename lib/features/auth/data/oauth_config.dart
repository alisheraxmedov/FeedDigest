import 'dart:convert';
import 'dart:math';

/// Reddit OAuth (Authorization Code, "installed app") configuration.
///
/// The [redirectUri] must be registered **exactly** in the Reddit app settings
/// (https://www.reddit.com/prefs/apps) and its [callbackScheme] must match the
/// scheme declared in AndroidManifest.xml / iOS Info.plist.
class OAuthConfig {
  const OAuthConfig._();

  static const String redirectUri = 'feeddigest://oauth2redirect';
  static const String callbackScheme = 'feeddigest';

  /// Mobile-optimized authorize page.
  static const String authorizeUrl =
      'https://www.reddit.com/api/v1/authorize.compact';

  static const String tokenUrl = 'https://www.reddit.com/api/v1/access_token';

  /// `permanent` is required to receive a refresh_token (otherwise the session
  /// dies after ~1h). Scopes: read public, read the user's subscriptions,
  /// subscribe/unsubscribe, and vote. (No comment scope — not needed.)
  static const List<String> scopes = [
    'identity',
    'mysubreddits',
    'read',
    'vote',
    'subscribe',
  ];

  /// Builds the full authorize URL the user is sent to in the browser.
  static String buildAuthUrl({
    required String clientId,
    required String state,
  }) {
    return Uri.parse(authorizeUrl).replace(queryParameters: {
      'client_id': clientId,
      'response_type': 'code',
      'state': state,
      'redirect_uri': redirectUri,
      'duration': 'permanent',
      'scope': scopes.join(' '),
    }).toString();
  }

  /// Cryptographically-random CSRF `state` value.
  static String generateState() {
    final rng = Random.secure();
    final bytes = List<int>.generate(24, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
