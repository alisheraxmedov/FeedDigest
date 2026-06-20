// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FeedDigest';

  @override
  String get navFeed => 'Feed';

  @override
  String get navSearch => 'Search';

  @override
  String get navSaved => 'Saved';

  @override
  String get navSettings => 'Settings';

  @override
  String get chipAll => 'All';

  @override
  String get feedNoSubscriptions =>
      'No topics yet. Add one with + or from Search.';

  @override
  String get feedEmpty => 'Nothing found';

  @override
  String get retry => 'Try again';

  @override
  String get sourcesTitle => 'Sources';

  @override
  String get openOriginal => 'Open original article';

  @override
  String get aiSummary => 'AI summary';

  @override
  String get close => 'Close';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Manage app and service parameters';

  @override
  String get geminiTitle => 'Gemini API key';

  @override
  String get geminiSubtitle => 'Connected key for core AI services';

  @override
  String get geminiKeySet => 'Key set';

  @override
  String get geminiKeyNotSet => 'Key not set';

  @override
  String get geminiHint => 'Enter API key...';

  @override
  String get save => 'Save';

  @override
  String get keySaved => 'Key saved';

  @override
  String get appLanguage => 'App language';

  @override
  String get aiSummaryLanguage => 'AI summary language';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get langUzbek => 'O\'zbekcha';

  @override
  String get langRussian => 'Русский';

  @override
  String get langEnglish => 'English';

  @override
  String get searchHint => 'Search articles...';

  @override
  String get searchEmpty => 'No search results';

  @override
  String get searchPrompt => 'Search by topic or keyword';

  @override
  String searchResultsFor(String query) {
    return 'Results for \'$query\'';
  }

  @override
  String get filter => 'Filter';

  @override
  String readingTime(int minutes) {
    return '$minutes min read';
  }

  @override
  String get savedTitle => 'Saved';

  @override
  String get savedEmpty => 'No saved posts yet';

  @override
  String get topicsTitle => 'Topics';

  @override
  String get topicLabel => 'Topic';

  @override
  String get add => 'Add';

  @override
  String get timeNow => 'now';

  @override
  String get tooltipSubscribe => 'Follow topic';

  @override
  String get tooltipUnsubscribe => 'Unfollow topic';

  @override
  String get summaryNoKey => 'Gemini API key not set';

  @override
  String get summaryFailed => 'Failed to get summary';

  @override
  String get sourceLabel => 'Source';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortPopular => 'Popular';
}
