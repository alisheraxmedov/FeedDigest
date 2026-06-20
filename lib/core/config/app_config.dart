class AppConfig {
  static const String userAgent = 'UzSummaryApp/1.0 (shaxsiy)';

  static const List<String> redditHosts = [
    'www.reddit.com',
    'old.reddit.com',
    'redlib.catsarch.com',
  ];

  static const String geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String geminiModel = 'gemini-2.5-flash';

  static const String topPeriod = 'week';
  static const int feedLimit = 10;
  static const int searchLimit = 25;
  static const int fetchConcurrency = 5;

  static const List<({String label, String subreddit})> defaultSubreddits = [
    (label: 'Flutter', subreddit: 'FlutterDev'),
    (label: 'Programming', subreddit: 'programming'),
    (label: 'Technology', subreddit: 'technology'),
  ];
}
