/// Authentication state for the Reddit account.
sealed class AuthState {
  const AuthState();

  bool get isLoggedIn => this is AuthLoggedIn;
  String? get username => switch (this) {
        AuthLoggedIn(:final username) => username,
        _ => null,
      };
}

class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}

class AuthLoggedIn extends AuthState {
  const AuthLoggedIn(this.username);

  @override
  final String username;
}
