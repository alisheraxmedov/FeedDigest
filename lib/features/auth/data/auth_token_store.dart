import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the long-lived Reddit refresh token (and cached username) in the
/// platform secure store (Keychain / Keystore). The access token is short-lived
/// and kept only in memory by the session.
class AuthTokenStore {
  AuthTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kRefresh = 'reddit_refresh_token';
  static const _kUsername = 'reddit_username';

  Future<void> save({
    required String refreshToken,
    required String username,
  }) async {
    await _storage.write(key: _kRefresh, value: refreshToken);
    await _storage.write(key: _kUsername, value: username);
  }

  Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);

  Future<String?> readUsername() => _storage.read(key: _kUsername);

  Future<void> clear() async {
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUsername);
  }
}
