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
  String get aiProviderTitle => 'AI-провайдер';

  @override
  String get aiKeySet => 'Ключ сохранён';

  @override
  String get aiKeyNotSet => 'Ключ не задан';

  @override
  String get aiModelLabel => 'Модель';

  @override
  String get aiKeyInvalid => 'Неверный API-ключ';

  @override
  String get aiRateLimited => 'Лимит исчерпан — попробуйте позже';

  @override
  String get voiceInfoTitle => 'Голосовой AI-поиск';

  @override
  String get voiceInfoSubtitle => 'Работает с Gemini';

  @override
  String get voiceInfoBody =>
      'Удерживайте кнопку микрофона на главном экране и скажите, о чём хотите почитать — AI превратит вашу речь в поисковый запрос.\n\nЭта функция понимает аудио только через Google Gemini, поэтому она доступна, когда Gemini выбран AI-провайдером и его ключ сохранён.';

  @override
  String get switchToGemini => 'Переключиться на Gemini';

  @override
  String get save => 'Сохранить';

  @override
  String get keySaved => 'Ключ сохранён';

  @override
  String get keySaveFailed => 'Не удалось сохранить ключ';

  @override
  String get notifScheduleFailed => 'Не удалось настроить напоминание';

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
  String get summaryNoKey => 'API-ключ AI не задан';

  @override
  String get summaryFailed => 'Не удалось получить резюме';

  @override
  String get sourceLabel => 'Источник';

  @override
  String get sortNewest => 'Сначала новые';

  @override
  String get sortPopular => 'Популярные';

  @override
  String get feedLoadError =>
      'Не удалось загрузить статьи. Проверьте подключение и повторите.';

  @override
  String get summaryBlocked => 'Заблокировано фильтром безопасности AI';

  @override
  String get summaryDepthBrief => 'Кратко';

  @override
  String get summaryDepthDetailed => 'Подробно';

  @override
  String get summaryAddKey => 'Добавить ключ';

  @override
  String get digestTitle => 'Дайджест дня';

  @override
  String get digestTooltip => 'AI ежедневный дайджест';

  @override
  String get notifDigestLabel => 'Дайджест дня';

  @override
  String get notifDigestDesc =>
      'Ежедневное напоминание почитать в выбранное время';

  @override
  String get notifTimeLabel => 'Время';

  @override
  String get notifBody => 'Дайджест дня готов — время читать!';

  @override
  String get notifDenied => 'Разрешение на уведомления не получено';

  @override
  String get notifOff => 'Выключено';

  @override
  String get translateTooltip => 'Перевести';

  @override
  String get chatTooltip => 'Чат по статье';

  @override
  String get chatTitle => 'Чат по статье';

  @override
  String get chatHint => 'Задайте вопрос...';

  @override
  String get chatEmpty => 'Спросите что угодно об этой статье';

  @override
  String get exportData => 'Экспорт данных';

  @override
  String get exportDataDesc => 'Подписки и сохранённое (JSON + OPML)';

  @override
  String get exportFailed => 'Ошибка экспорта';

  @override
  String get readerText => 'Размер текста';

  @override
  String get readerTextSample =>
      'Пример текста — выберите удобный для чтения размер.';

  @override
  String streakDays(int count) {
    return '$count дней подряд';
  }

  @override
  String get menu => 'Меню';

  @override
  String get sortLabel => 'Сортировка';

  @override
  String get streakTitle => 'Серия чтения';

  @override
  String get streakNone => 'Серии пока нет';

  @override
  String get sectionMore => 'Ещё';

  @override
  String get about => 'О приложении';

  @override
  String get aboutDescription =>
      'Читалка Hacker News + dev.to с ИИ-обзорами Gemini.';

  @override
  String version(String version) {
    return 'Версия $version';
  }

  @override
  String get shareApp => 'Поделиться приложением';

  @override
  String get shareAppText =>
      'Попробуйте FeedDigest — читалку Hacker News + dev.to с ИИ-обзорами.';

  @override
  String get rateApp => 'Оценить приложение';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get termsOfService => 'Условия использования';

  @override
  String get support => 'Поддержка';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get sectionComingSoon => 'Этот раздел скоро появится.';

  @override
  String get onboardingTagline =>
      'Статьи Hacker News и dev.to — кратко от AI за секунды.';

  @override
  String get onboardingFeatureAiTitle => 'AI-резюме на вашем языке';

  @override
  String get onboardingFeatureAiSub => 'Узбекский · Русский · Английский';

  @override
  String get onboardingFeatureSourcesTitle => 'Два источника, одна лента';

  @override
  String get onboardingFeatureSourcesSub => 'Объединено и без дублей';

  @override
  String get onboardingFeatureSaveTitle => 'Сохранить и прочитать позже';

  @override
  String get onboardingFeatureSaveSub => 'Закладки с фильтром по темам';

  @override
  String get onboardingGetStarted => 'Начать';

  @override
  String get onboardingKeyHint =>
      'Добавьте ключ Gemini API в настройках для AI-функций.';

  @override
  String get onboardingOpenSettings => 'Открыть настройки';

  @override
  String get netOffline => 'Нет подключения к интернету';

  @override
  String get netOnline => 'Соединение восстановлено';

  @override
  String get voiceHoldHint => 'Удерживайте, чтобы говорить';

  @override
  String get voiceListening => 'Слушаю…';

  @override
  String get voiceProcessing => 'Распознаю…';

  @override
  String get voiceEmpty => 'Не расслышал — попробуйте снова';

  @override
  String get voiceNoPermission => 'Нужен доступ к микрофону';

  @override
  String get voiceFailed => 'Голосовой поиск не удался';

  @override
  String get interestsTitle => 'Выберите интересы';

  @override
  String get interestsSubtitle =>
      'Выберите несколько тем для ленты. Изменить можно в настройках в любое время.';

  @override
  String get interestsContinue => 'Продолжить';

  @override
  String get interestsSkip => 'Пропустить';
}
