/*
App-level user preferences, each persisted in the Hive `meta` box so it survives
restarts: the UI language, the theme mode (defaults to dark), and the AI summary
language (null = follow the UI language). effectiveAiLangProvider resolves that
fallback for the Gemini layer.
*/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final localeProvider =
    NotifierProvider<LocaleController, AppLanguage>(LocaleController.new);

class LocaleController extends Notifier<AppLanguage> {
  static const String _key = 'app_locale';

  @override
  AppLanguage build() =>
      AppLanguage.fromCode(ref.read(metaBoxProvider).get(_key) as String?);

  void select(AppLanguage lang) {
    ref.read(metaBoxProvider).put(_key, lang.code);
    state = lang;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  static const String _key = 'theme_mode';

  @override
  ThemeMode build() => _decode(ref.read(metaBoxProvider).get(_key) as String?);

  void select(ThemeMode mode) {
    ref.read(metaBoxProvider).put(_key, mode.name);
    state = mode;
  }

  static ThemeMode _decode(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
}

final aiSummaryLangProvider =
    NotifierProvider<AiSummaryLangController, AppLanguage?>(
        AiSummaryLangController.new);

class AiSummaryLangController extends Notifier<AppLanguage?> {
  static const String _key = 'ai_summary_lang';

  @override
  AppLanguage? build() {
    final code = ref.read(metaBoxProvider).get(_key) as String?;
    return code == null ? null : AppLanguage.fromCode(code);
  }

  void select(AppLanguage lang) {
    ref.read(metaBoxProvider).put(_key, lang.code);
    state = lang;
  }
}

final effectiveAiLangProvider = Provider<AppLanguage>(
    (ref) => ref.watch(aiSummaryLangProvider) ?? ref.watch(localeProvider));
