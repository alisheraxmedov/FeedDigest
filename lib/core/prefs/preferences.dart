/*
App-level user preferences, each persisted in the Hive `meta` box so it survives
restarts: the UI language, the theme mode (defaults to dark), and the AI summary
language (null = follow the UI language). effectiveAiLangProvider resolves that
fallback for the Gemini layer.
*/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/ai_provider.dart';
import '../providers.dart';

enum AppLanguage {
  uz('uz', "O'zbekcha"),
  ru('ru', 'Русский'),
  en('en', 'English');

  const AppLanguage(this.code, this.nativeLabel);

  final String code;
  final String nativeLabel;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) => AppLanguage.values.firstWhere(
    (lang) => lang.code == code,
    orElse: () => AppLanguage.uz,
  );
}

final localeProvider = NotifierProvider<LocaleController, AppLanguage>(
  LocaleController.new,
);

class LocaleController extends Notifier<AppLanguage> {
  static const String _key = 'app_locale';

  @override
  AppLanguage build() =>
      AppLanguage.fromCode(ref.read(metaBoxProvider).get(_key) as String?);

  Future<void> select(AppLanguage lang) async {
    state = lang;
    final box = ref.read(metaBoxProvider);
    await box.put(_key, lang.code);
    await box.flush();
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  static const String _key = 'theme_mode';

  @override
  ThemeMode build() => _decode(ref.read(metaBoxProvider).get(_key) as String?);

  Future<void> select(ThemeMode mode) async {
    state = mode;
    final box = ref.read(metaBoxProvider);
    await box.put(_key, mode.name);
    await box.flush();
  }

  static ThemeMode _decode(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };
}

/// Which AI backend runs the text features. Voice search stays Gemini-only,
/// so the voice FAB is hidden whenever this isn't gemini.
final aiProviderProvider = NotifierProvider<AiProviderController, AiProvider>(
  AiProviderController.new,
);

class AiProviderController extends Notifier<AiProvider> {
  static const String _key = 'ai_provider';

  @override
  AiProvider build() =>
      AiProvider.fromId(ref.read(metaBoxProvider).get(_key) as String?);

  Future<void> select(AiProvider provider) async {
    state = provider;
    final box = ref.read(metaBoxProvider);
    await box.put(_key, provider.id);
    await box.flush();
  }
}

final aiSummaryLangProvider =
    NotifierProvider<AiSummaryLangController, AppLanguage?>(
      AiSummaryLangController.new,
    );

class AiSummaryLangController extends Notifier<AppLanguage?> {
  static const String _key = 'ai_summary_lang';

  @override
  AppLanguage? build() {
    final code = ref.read(metaBoxProvider).get(_key) as String?;
    return code == null ? null : AppLanguage.fromCode(code);
  }

  Future<void> select(AppLanguage lang) async {
    state = lang;
    final box = ref.read(metaBoxProvider);
    await box.put(_key, lang.code);
    await box.flush();
  }
}

final effectiveAiLangProvider = Provider<AppLanguage>(
  (ref) => ref.watch(aiSummaryLangProvider) ?? ref.watch(localeProvider),
);

/// How much detail the AI summary should carry. `brief` is a short TL;DR;
/// `detailed` is the full section-by-section summary. Persisted in the meta box.
enum SummaryDepth {
  brief('brief'),
  detailed('detailed');

  const SummaryDepth(this.code);

  final String code;

  bool get isBrief => this == SummaryDepth.brief;

  static SummaryDepth fromCode(String? code) => SummaryDepth.values.firstWhere(
    (depth) => depth.code == code,
    orElse: () => SummaryDepth.detailed,
  );
}

final summaryDepthProvider =
    NotifierProvider<SummaryDepthController, SummaryDepth>(
      SummaryDepthController.new,
    );

class SummaryDepthController extends Notifier<SummaryDepth> {
  static const String _key = 'summary_depth';

  @override
  SummaryDepth build() =>
      SummaryDepth.fromCode(ref.read(metaBoxProvider).get(_key) as String?);

  Future<void> select(SummaryDepth depth) async {
    state = depth;
    final box = ref.read(metaBoxProvider);
    await box.put(_key, depth.code);
    await box.flush();
  }
}

/// Reading text scale for the article detail screen, persisted in the meta box.
/// Composed with the system text scale rather than replacing it.
final readerTextScaleProvider =
    NotifierProvider<ReaderTextScaleController, double>(
      ReaderTextScaleController.new,
    );

class ReaderTextScaleController extends Notifier<double> {
  static const String _key = 'reader_text_scale';
  static const double minScale = 0.85;
  static const double maxScale = 1.6;

  @override
  double build() {
    final value = ref.read(metaBoxProvider).get(_key);
    return value is num ? value.toDouble().clamp(minScale, maxScale) : 1.0;
  }

  Future<void> set(double value) async {
    final clamped = value.clamp(minScale, maxScale);
    state = clamped;
    final box = ref.read(metaBoxProvider);
    await box.put(_key, clamped);
    await box.flush();
  }
}

/// Daily digest reminder settings, persisted in the meta box. The actual OS
/// scheduling lives in NotificationService; this only holds the user's choice.
class NotificationPrefs {
  const NotificationPrefs({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;

  String get hhmm =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  NotificationPrefs copyWith({bool? enabled, int? hour, int? minute}) =>
      NotificationPrefs(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsController, NotificationPrefs>(
      NotificationPrefsController.new,
    );

class NotificationPrefsController extends Notifier<NotificationPrefs> {
  static const String _kEnabled = 'digest_notif_enabled';
  static const String _kHour = 'digest_notif_hour';
  static const String _kMinute = 'digest_notif_minute';

  @override
  NotificationPrefs build() {
    final box = ref.read(metaBoxProvider);
    return NotificationPrefs(
      enabled: box.get(_kEnabled) as bool? ?? false,
      hour: box.get(_kHour) as int? ?? 9,
      minute: box.get(_kMinute) as int? ?? 0,
    );
  }

  Future<void> save(NotificationPrefs prefs) async {
    state = prefs;
    final box = ref.read(metaBoxProvider);
    await box.put(_kEnabled, prefs.enabled);
    await box.put(_kHour, prefs.hour);
    await box.put(_kMinute, prefs.minute);
    await box.flush();
  }
}
