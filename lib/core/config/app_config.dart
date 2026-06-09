import '../models/topic.dart';

/// App-wide constants and default configuration.
class AppConfig {
  const AppConfig._();

  static const String appName = 'FeedDigest';

  // --- Reddit endpoints -----------------------------------------------------

  /// Public, unauthenticated JSON API host.
  static const String redditPublicBase = 'https://www.reddit.com';

  /// OAuth-authenticated API host (used when a client id is configured).
  static const String redditOAuthBase = 'https://oauth.reddit.com';

  static const String redditTokenUrl =
      'https://www.reddit.com/api/v1/access_token';

  /// Number of posts requested per page.
  static const int pageSize = 20;

  // --- Gemini endpoint ------------------------------------------------------

  static const String geminiBase =
      'https://generativelanguage.googleapis.com/v1beta';

  // --- Persistence keys -----------------------------------------------------

  static const String prefsTopics = 'pref_topics_v1';
  static const String prefsThemeMode = 'pref_theme_mode_v1';

  /// Categories shown on the home screen out of the box. The user can edit,
  /// add or remove these from the Settings screen and the changes persist.
  static const List<Topic> defaultTopics = [
    Topic(label: 'Flutter', subreddit: 'FlutterDev'),
    Topic(label: 'IT', subreddit: 'programming'),
    Topic(label: 'AI', subreddit: 'artificial'),
    Topic(label: 'Android', subreddit: 'androiddev'),
    Topic(label: 'iOS', subreddit: 'iOSProgramming'),
    Topic(label: 'Texnologiya', subreddit: 'technology'),
  ];
}

/// Listing sort modes supported by the feed.
enum FeedSort {
  hot('hot', 'Hot'),
  newest('new', 'Yangi'),
  top('top', 'Top'),
  rising('rising', 'Ko‘tarilayotgan');

  const FeedSort(this.value, this.label);

  /// Path segment used by the Reddit API (`/r/<sub>/<value>.json`).
  final String value;

  /// Human-readable label shown in the UI.
  final String label;
}
