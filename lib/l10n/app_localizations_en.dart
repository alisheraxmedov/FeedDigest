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
  String get articleShort => 'Article';

  @override
  String get aiShort => 'AI';

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
  String get keySaveFailed => 'Couldn\'t save the key';

  @override
  String get notifScheduleFailed => 'Couldn\'t set the reminder';

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

  @override
  String get feedLoadError =>
      'Couldn\'t load articles. Check your connection and try again.';

  @override
  String get summaryBlocked => 'Blocked by the AI safety filter';

  @override
  String get summaryDepthBrief => 'Brief';

  @override
  String get summaryDepthDetailed => 'Detailed';

  @override
  String get summaryAddKey => 'Add key';

  @override
  String get digestTitle => 'Today\'s digest';

  @override
  String get digestTooltip => 'AI daily digest';

  @override
  String get notifDigestLabel => 'Daily digest';

  @override
  String get notifDigestDesc => 'A daily reminder to read at your chosen time';

  @override
  String get notifTimeLabel => 'Time';

  @override
  String get notifBody => 'Your daily digest is ready — time to read!';

  @override
  String get notifDenied => 'Notification permission denied';

  @override
  String get notifOff => 'Off';

  @override
  String get translateTooltip => 'Translate';

  @override
  String get chatTooltip => 'Chat about article';

  @override
  String get chatTitle => 'Chat about article';

  @override
  String get chatHint => 'Ask a question...';

  @override
  String get chatEmpty => 'Ask anything about this article';

  @override
  String get exportData => 'Export data';

  @override
  String get exportDataDesc => 'Subscriptions and saved (JSON + OPML)';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get readerText => 'Text size';

  @override
  String get readerTextSample =>
      'Sample text — pick a comfortable reading size.';

  @override
  String streakDays(int count) {
    return '$count-day reading streak';
  }

  @override
  String get menu => 'Menu';

  @override
  String get sortLabel => 'Sort';

  @override
  String get streakTitle => 'Reading streak';

  @override
  String get streakNone => 'No streak yet';

  @override
  String get sectionMore => 'More';

  @override
  String get about => 'About';

  @override
  String get aboutDescription =>
      'Hacker News + dev.to reader with Gemini AI summaries.';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get shareApp => 'Share app';

  @override
  String get shareAppText =>
      'Check out FeedDigest — a Hacker News + dev.to reader with AI summaries.';

  @override
  String get rateApp => 'Rate the app';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get support => 'Support';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get sectionComingSoon => 'This section will be available soon.';

  @override
  String get onboardingTagline =>
      'Hacker News & dev.to stories, summarized by AI in seconds.';

  @override
  String get onboardingFeatureAiTitle => 'AI summaries, your language';

  @override
  String get onboardingFeatureAiSub => 'Uzbek · Russian · English';

  @override
  String get onboardingFeatureSourcesTitle => 'Two sources, one feed';

  @override
  String get onboardingFeatureSourcesSub => 'Merged & de-duplicated';

  @override
  String get onboardingFeatureSaveTitle => 'Save & read later';

  @override
  String get onboardingFeatureSaveSub => 'Bookmarks, filtered by topic';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingKeyHint =>
      'Add your Gemini API key in Settings to unlock AI features.';

  @override
  String get onboardingOpenSettings => 'Open Settings';

  @override
  String get netOffline => 'No internet connection';

  @override
  String get netOnline => 'Back online';

  @override
  String get voiceHoldHint => 'Hold to speak';

  @override
  String get voiceListening => 'Listening…';

  @override
  String get voiceProcessing => 'Understanding…';

  @override
  String get voiceEmpty => 'Didn\'t catch that — try again';

  @override
  String get voiceNoPermission => 'Microphone permission is needed';

  @override
  String get voiceFailed => 'Voice search failed';
}
