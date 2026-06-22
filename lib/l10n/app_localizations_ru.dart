// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'FeedDigest';

  @override
  String get navFeed => 'Лента';

  @override
  String get navSearch => 'Поиск';

  @override
  String get navSaved => 'Сохранённые';

  @override
  String get navSettings => 'Настройки';

  @override
  String get chipAll => 'Все';

  @override
  String get feedNoSubscriptions => 'Нет тем. Добавьте через + или Поиск.';

  @override
  String get feedEmpty => 'Ничего не найдено';

  @override
  String get retry => 'Повторить';

  @override
  String get sourcesTitle => 'Источники';

  @override
  String get openOriginal => 'Открыть оригинал';

  @override
  String get aiSummary => 'AI-резюме';

  @override
  String get articleShort => 'Статья';

  @override
  String get aiShort => 'AI';

  @override
  String get close => 'Закрыть';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSubtitle => 'Управление параметрами приложения и сервиса';

  @override
  String get geminiTitle => 'Ключ Gemini API';

  @override
  String get geminiSubtitle => 'Подключённый ключ для основных AI-сервисов';

  @override
  String get geminiKeySet => 'Ключ установлен';

  @override
  String get geminiKeyNotSet => 'Ключ не установлен';

  @override
  String get geminiHint => 'Введите API-ключ...';

  @override
  String get save => 'Сохранить';

  @override
  String get keySaved => 'Ключ сохранён';

  @override
  String get appLanguage => 'Язык приложения';

  @override
  String get aiSummaryLanguage => 'Язык AI-резюме';

  @override
  String get theme => 'Тема';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get langUzbek => 'O\'zbekcha';

  @override
  String get langRussian => 'Русский';

  @override
  String get langEnglish => 'English';

  @override
  String get searchHint => 'Поиск статей...';

  @override
  String get searchEmpty => 'Нет результатов поиска';

  @override
  String get searchPrompt => 'Ищите по теме или ключевому слову';

  @override
  String searchResultsFor(String query) {
    return 'Результаты по «$query»';
  }

  @override
  String get filter => 'Фильтр';

  @override
  String readingTime(int minutes) {
    return '$minutes мин чтения';
  }

  @override
  String get savedTitle => 'Сохранённые';

  @override
  String get savedEmpty => 'Пока нет сохранённых статей';

  @override
  String get topicsTitle => 'Темы';

  @override
  String get topicLabel => 'Тема';

  @override
  String get add => 'Добавить';

  @override
  String get timeNow => 'сейчас';

  @override
  String get tooltipSubscribe => 'Подписаться на тему';

  @override
  String get tooltipUnsubscribe => 'Отписаться от темы';

  @override
  String get summaryNoKey => 'Ключ Gemini API не установлен';

  @override
  String get summaryFailed => 'Не удалось получить резюме';

  @override
  String get sourceLabel => 'Источник';

  @override
  String get sortNewest => 'Сначала новые';

  @override
  String get sortPopular => 'Популярные';
}
