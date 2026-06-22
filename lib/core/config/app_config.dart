class AppConfig {
  static const String geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String geminiModel = 'gemini-2.5-flash';

  static const String hackerNewsHost = 'hn.algolia.com';
  static const String devtoHost = 'dev.to';
  static const int devtoTopDays = 7;

  static const int feedLimit = 15;
  static const int searchLimit = 25;
  static const int fetchConcurrency = 5;

  static const List<({String label, String topic})> defaultTopics = [
    (label: 'Flutter', topic: 'flutter'),
    (label: 'Programming', topic: 'programming'),
    (label: 'Technology', topic: 'technology'),
  ];
}
