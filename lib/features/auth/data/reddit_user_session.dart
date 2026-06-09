import '../../../core/config/env.dart';
import '../../feed/data/reddit_auth.dart';
import 'auth_token_store.dart';
import 'reddit_oauth_service.dart';

/// Holds the logged-in user's short-lived access token and refreshes it on
/// demand with **single-flight** semantics: many simultaneous 401s trigger one
/// refresh, not a storm.
class RedditUserSession {
  RedditUserSession({
    required RedditOAuthService oauth,
    required AuthTokenStore store,
    required this.clientId,
    required this.username,
    required String accessToken,
    required DateTime expiresAt,
    required String refreshToken,
  })  : _oauth = oauth,
        _store = store,
        _accessToken = accessToken,
        _expiresAt = expiresAt,
        _refreshToken = refreshToken;

  final RedditOAuthService _oauth;
  final AuthTokenStore _store;
  final String clientId;
  final String username;

  String _accessToken;
  DateTime _expiresAt;
  String _refreshToken;
  Future<String>? _refreshing;

  bool get _isFresh =>
      DateTime.now().isBefore(_expiresAt.subtract(const Duration(seconds: 60)));

  /// Returns a valid access token, refreshing if it is about to expire.
  Future<String> validAccessToken() {
    if (_isFresh) return Future.value(_accessToken);
    return _refreshing ??=
        _refresh().whenComplete(() => _refreshing = null);
  }

  Future<String> _refresh() async {
    final t = await _oauth.refresh(_refreshToken, clientId);
    _accessToken = t.accessToken;
    _expiresAt = DateTime.now().add(Duration(seconds: t.expiresIn));
    // Reddit may rotate the refresh token; persist the new one if present.
    if (t.refreshToken != null && t.refreshToken!.isNotEmpty) {
      _refreshToken = t.refreshToken!;
      await _store.save(refreshToken: _refreshToken, username: username);
    }
    return _accessToken;
  }
}

/// The live bearer-token source used by the Reddit repository.
///
/// Resolution is read **per request** (never captured at construction):
/// logged-in user token → app-only installed_client token → null (public).
class RedditTokenProvider {
  RedditTokenProvider({
    required RedditUserSession? Function() readSession,
    RedditAuth? appAuth,
  })  : _readSession = readSession,
        _appAuth = appAuth ?? RedditAuth();

  final RedditUserSession? Function() _readSession;
  final RedditAuth _appAuth;

  bool get isUserAuthenticated => _readSession() != null;

  Future<String?> bearerToken() async {
    final session = _readSession();
    if (session != null) return session.validAccessToken();
    if (Env.hasRedditAuth) return _appAuth.token();
    return null; // public .json endpoints
  }
}
