import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FeedDigest'**
  String get appTitle;

  /// No description provided for @navFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get navFeed;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get navSaved;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @chipAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get chipAll;

  /// No description provided for @feedNoSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No topics yet. Add one with + or from Search.'**
  String get feedNoSubscriptions;

  /// No description provided for @feedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get feedEmpty;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @sourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sourcesTitle;

  /// No description provided for @openOriginal.
  ///
  /// In en, this message translates to:
  /// **'Open original article'**
  String get openOriginal;

  /// No description provided for @aiSummary.
  ///
  /// In en, this message translates to:
  /// **'AI summary'**
  String get aiSummary;

  /// No description provided for @articleShort.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get articleShort;

  /// No description provided for @aiShort.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get aiShort;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage app and service parameters'**
  String get settingsSubtitle;

  /// No description provided for @geminiTitle.
  ///
  /// In en, this message translates to:
  /// **'Gemini API key'**
  String get geminiTitle;

  /// No description provided for @geminiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connected key for core AI services'**
  String get geminiSubtitle;

  /// No description provided for @geminiKeySet.
  ///
  /// In en, this message translates to:
  /// **'Key set'**
  String get geminiKeySet;

  /// No description provided for @geminiKeyNotSet.
  ///
  /// In en, this message translates to:
  /// **'Key not set'**
  String get geminiKeyNotSet;

  /// No description provided for @geminiHint.
  ///
  /// In en, this message translates to:
  /// **'Enter API key...'**
  String get geminiHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @keySaved.
  ///
  /// In en, this message translates to:
  /// **'Key saved'**
  String get keySaved;

  /// No description provided for @keySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the key'**
  String get keySaveFailed;

  /// No description provided for @notifScheduleFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t set the reminder'**
  String get notifScheduleFailed;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @aiSummaryLanguage.
  ///
  /// In en, this message translates to:
  /// **'AI summary language'**
  String get aiSummaryLanguage;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @langUzbek.
  ///
  /// In en, this message translates to:
  /// **'O\'zbekcha'**
  String get langUzbek;

  /// No description provided for @langRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get langRussian;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search articles...'**
  String get searchHint;

  /// No description provided for @searchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get searchEmpty;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Search by topic or keyword'**
  String get searchPrompt;

  /// No description provided for @searchResultsFor.
  ///
  /// In en, this message translates to:
  /// **'Results for \'{query}\''**
  String searchResultsFor(String query);

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @readingTime.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min read'**
  String readingTime(int minutes);

  /// No description provided for @savedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTitle;

  /// No description provided for @savedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved posts yet'**
  String get savedEmpty;

  /// No description provided for @topicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get topicsTitle;

  /// No description provided for @topicLabel.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get topicLabel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @timeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeNow;

  /// No description provided for @tooltipSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Follow topic'**
  String get tooltipSubscribe;

  /// No description provided for @tooltipUnsubscribe.
  ///
  /// In en, this message translates to:
  /// **'Unfollow topic'**
  String get tooltipUnsubscribe;

  /// No description provided for @summaryNoKey.
  ///
  /// In en, this message translates to:
  /// **'Gemini API key not set'**
  String get summaryNoKey;

  /// No description provided for @summaryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get summary'**
  String get summaryFailed;

  /// No description provided for @sourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceLabel;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get sortPopular;

  /// No description provided for @feedLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load articles. Check your connection and try again.'**
  String get feedLoadError;

  /// No description provided for @summaryBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked by the AI safety filter'**
  String get summaryBlocked;

  /// No description provided for @summaryDepthBrief.
  ///
  /// In en, this message translates to:
  /// **'Brief'**
  String get summaryDepthBrief;

  /// No description provided for @summaryDepthDetailed.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get summaryDepthDetailed;

  /// No description provided for @summaryAddKey.
  ///
  /// In en, this message translates to:
  /// **'Add key'**
  String get summaryAddKey;

  /// No description provided for @digestTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s digest'**
  String get digestTitle;

  /// No description provided for @digestTooltip.
  ///
  /// In en, this message translates to:
  /// **'AI daily digest'**
  String get digestTooltip;

  /// No description provided for @notifDigestLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily digest'**
  String get notifDigestLabel;

  /// No description provided for @notifDigestDesc.
  ///
  /// In en, this message translates to:
  /// **'A daily reminder to read at your chosen time'**
  String get notifDigestDesc;

  /// No description provided for @notifTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get notifTimeLabel;

  /// No description provided for @notifBody.
  ///
  /// In en, this message translates to:
  /// **'Your daily digest is ready — time to read!'**
  String get notifBody;

  /// No description provided for @notifDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied'**
  String get notifDenied;

  /// No description provided for @notifOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notifOff;

  /// No description provided for @translateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translateTooltip;

  /// No description provided for @chatTooltip.
  ///
  /// In en, this message translates to:
  /// **'Chat about article'**
  String get chatTooltip;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat about article'**
  String get chatTitle;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Ask a question...'**
  String get chatHint;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about this article'**
  String get chatEmpty;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @exportDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions and saved (JSON + OPML)'**
  String get exportDataDesc;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @readerText.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get readerText;

  /// No description provided for @readerTextSample.
  ///
  /// In en, this message translates to:
  /// **'Sample text — pick a comfortable reading size.'**
  String get readerTextSample;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count}-day reading streak'**
  String streakDays(int count);

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @sortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortLabel;

  /// No description provided for @streakTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading streak'**
  String get streakTitle;

  /// No description provided for @streakNone.
  ///
  /// In en, this message translates to:
  /// **'No streak yet'**
  String get streakNone;

  /// No description provided for @sectionMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get sectionMore;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Hacker News + dev.to reader with Gemini AI summaries.'**
  String get aboutDescription;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share app'**
  String get shareApp;

  /// No description provided for @shareAppText.
  ///
  /// In en, this message translates to:
  /// **'Check out FeedDigest — a Hacker News + dev.to reader with AI summaries.'**
  String get shareAppText;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the app'**
  String get rateApp;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @sectionComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This section will be available soon.'**
  String get sectionComingSoon;

  /// No description provided for @onboardingTagline.
  ///
  /// In en, this message translates to:
  /// **'Hacker News & dev.to stories, summarized by AI in seconds.'**
  String get onboardingTagline;

  /// No description provided for @onboardingFeatureAiTitle.
  ///
  /// In en, this message translates to:
  /// **'AI summaries, your language'**
  String get onboardingFeatureAiTitle;

  /// No description provided for @onboardingFeatureAiSub.
  ///
  /// In en, this message translates to:
  /// **'Uzbek · Russian · English'**
  String get onboardingFeatureAiSub;

  /// No description provided for @onboardingFeatureSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Two sources, one feed'**
  String get onboardingFeatureSourcesTitle;

  /// No description provided for @onboardingFeatureSourcesSub.
  ///
  /// In en, this message translates to:
  /// **'Merged & de-duplicated'**
  String get onboardingFeatureSourcesSub;

  /// No description provided for @onboardingFeatureSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save & read later'**
  String get onboardingFeatureSaveTitle;

  /// No description provided for @onboardingFeatureSaveSub.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks, filtered by topic'**
  String get onboardingFeatureSaveSub;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Add your Gemini API key in Settings to unlock AI features.'**
  String get onboardingKeyHint;

  /// No description provided for @onboardingOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get onboardingOpenSettings;

  /// No description provided for @netOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get netOffline;

  /// No description provided for @netOnline.
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get netOnline;

  /// No description provided for @voiceHoldHint.
  ///
  /// In en, this message translates to:
  /// **'Hold to speak'**
  String get voiceHoldHint;

  /// No description provided for @voiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get voiceListening;

  /// No description provided for @voiceProcessing.
  ///
  /// In en, this message translates to:
  /// **'Understanding…'**
  String get voiceProcessing;

  /// No description provided for @voiceEmpty.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t catch that — try again'**
  String get voiceEmpty;

  /// No description provided for @voiceNoPermission.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is needed'**
  String get voiceNoPermission;

  /// No description provided for @voiceFailed.
  ///
  /// In en, this message translates to:
  /// **'Voice search failed'**
  String get voiceFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
