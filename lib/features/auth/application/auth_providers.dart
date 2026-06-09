import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../data/auth_token_store.dart';
import '../data/reddit_oauth_service.dart';
import '../data/reddit_user_session.dart';
import 'auth_state.dart';

final authTokenStoreProvider =
    Provider<AuthTokenStore>((ref) => AuthTokenStore());

final redditOAuthServiceProvider =
    Provider<RedditOAuthService>((ref) => RedditOAuthService());

/// Owns the auth lifecycle: restore on start, login, logout. Holds the live
/// [RedditUserSession] used by the token provider.
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends AsyncNotifier<AuthState> {
  RedditUserSession? _session;
  RedditUserSession? get session => _session;

  AuthTokenStore get _store => ref.read(authTokenStoreProvider);
  RedditOAuthService get _oauth => ref.read(redditOAuthServiceProvider);

  @override
  Future<AuthState> build() async {
    final refresh = await _store.readRefreshToken();
    final username = await _store.readUsername();
    final clientId = Env.redditClientId;
    if (refresh == null || refresh.isEmpty || clientId.isEmpty) {
      return const AuthLoggedOut();
    }
    try {
      final t = await _oauth.refresh(refresh, clientId);
      _session = _sessionFrom(
        clientId: clientId,
        username: username ?? 'reddit',
        accessToken: t.accessToken,
        expiresIn: t.expiresIn,
        refreshToken:
            (t.refreshToken?.isNotEmpty ?? false) ? t.refreshToken! : refresh,
      );
      return AuthLoggedIn(_session!.username);
    } catch (_) {
      // Stored token revoked/invalid — fall back to logged out.
      await _store.clear();
      _session = null;
      return const AuthLoggedOut();
    }
  }

  /// Runs the interactive browser login.
  Future<void> login() async {
    state = const AsyncLoading<AuthState>();
    state = await AsyncValue.guard(() async {
      final result = await _oauth.login();
      final refreshToken = result.token.refreshToken ?? '';
      await _store.save(refreshToken: refreshToken, username: result.username);
      _session = _sessionFrom(
        clientId: Env.redditClientId,
        username: result.username,
        accessToken: result.token.accessToken,
        expiresIn: result.token.expiresIn,
        refreshToken: refreshToken,
      );
      return AuthLoggedIn(result.username);
    });
  }

  Future<void> logout() async {
    await _store.clear();
    _session = null;
    state = const AsyncData(AuthLoggedOut());
  }

  RedditUserSession _sessionFrom({
    required String clientId,
    required String username,
    required String accessToken,
    required int expiresIn,
    required String refreshToken,
  }) {
    return RedditUserSession(
      oauth: _oauth,
      store: _store,
      clientId: clientId,
      username: username,
      accessToken: accessToken,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      refreshToken: refreshToken,
    );
  }
}

/// Derived booleans/strings the UI and repository watch so they react to
/// login/logout automatically.
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).value?.isLoggedIn ?? false;
});

final currentUsernameProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider).value?.username;
});

/// The live token source for the Reddit repository. Reads the current session
/// lazily (per request), so the repo switches to the user token the moment
/// login completes.
final redditTokenProvider = Provider<RedditTokenProvider>((ref) {
  return RedditTokenProvider(
    readSession: () => ref.read(authControllerProvider.notifier).session,
  );
});
