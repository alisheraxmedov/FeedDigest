import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads the `.env` file once at app start.
///
/// The file is optional: if it is missing or unreadable the app still launches
/// and transparently falls back to the bundled mock data sources, so everything
/// is demoable before any API keys are provided.
class EnvLoader {
  const EnvLoader._();

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // No `.env` asset (or malformed). We deliberately leave dotenv
      // uninitialised; [Env._get] guards on `isInitialized` and returns
      // fallbacks, so the app launches on mock data.
    }
  }
}

/// Typed, centralised access to environment values.
///
/// Every key is optional. Credential getters such as [hasGemini] /
/// [useRealReddit] let the providers decide between the live and mock
/// implementations.
class Env {
  const Env._();

  static String _get(String key, {String fallback = ''}) {
    if (!dotenv.isInitialized) return fallback;
    final value = dotenv.env[key];
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  static bool _flag(String key) => _get(key).toLowerCase() == 'true';

  // --- Gemini ---------------------------------------------------------------

  static String get geminiApiKey => _get('GEMINI_API_KEY');

  /// Overridable so a wrong model id is a one-line `.env` fix, not a code edit.
  static String get geminiModel =>
      _get('GEMINI_MODEL', fallback: 'gemini-2.5-flash');

  static bool get hasGemini => geminiApiKey.isNotEmpty;

  // --- Reddit ---------------------------------------------------------------

  static String get redditClientId => _get('REDDIT_CLIENT_ID');

  /// Reddit aggressively rate-limits requests without a descriptive User-Agent.
  static String get redditUserAgent => _get(
        'REDDIT_USER_AGENT',
        fallback: 'android:com.feeddigest.app:1.0.0 (by /u/anonymous)',
      );

  /// When true, live data is read from the public `.json` endpoints even
  /// without OAuth credentials. Datacenter IPs are often throttled by Reddit,
  /// so this stays opt-in.
  static bool get redditUsePublic => _flag('REDDIT_USE_PUBLIC');

  static bool get hasRedditAuth => redditClientId.isNotEmpty;

  /// Use the live Reddit repository when we have OAuth credentials or the user
  /// explicitly opted into the public endpoints; otherwise use the mock.
  static bool get useRealReddit => hasRedditAuth || redditUsePublic;
}
