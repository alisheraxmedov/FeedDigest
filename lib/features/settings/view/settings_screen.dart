import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/prefs/preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../feed/view/widgets/source_switcher.dart';
import '../../feed/viewmodel/feed_source_viewmodel.dart';
import '../viewmodel/settings_viewmodel.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _key = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(settingsActionsProvider).saveKey(_key.text);
    if (!mounted) return;
    _key.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).keySaved)),
    );
  }

  String _themeLabel(AppLocalizations l, ThemeMode mode) => switch (mode) {
        ThemeMode.system => l.themeSystem,
        ThemeMode.light => l.themeLight,
        ThemeMode.dark => l.themeDark,
      };

  void _pickAppLanguage(AppLocalizations l) {
    showOptionPicker<AppLanguage>(
      context: context,
      title: l.appLanguage,
      selected: ref.read(localeProvider),
      options: [
        for (final lang in AppLanguage.values)
          PickerOption(value: lang, label: lang.nativeLabel, icon: Icons.language),
      ],
      onSelected: (lang) => ref.read(localeProvider.notifier).select(lang),
    );
  }

  void _pickAiLanguage(AppLocalizations l) {
    showOptionPicker<AppLanguage>(
      context: context,
      title: l.aiSummaryLanguage,
      selected: ref.read(effectiveAiLangProvider),
      options: [
        for (final lang in AppLanguage.values)
          PickerOption(value: lang, label: lang.nativeLabel, icon: Icons.translate),
      ],
      onSelected: (lang) =>
          ref.read(aiSummaryLangProvider.notifier).select(lang),
    );
  }

  void _pickTheme(AppLocalizations l) {
    showOptionPicker<ThemeMode>(
      context: context,
      title: l.theme,
      selected: ref.read(themeModeProvider),
      options: [
        PickerOption(
            value: ThemeMode.system,
            label: l.themeSystem,
            icon: Icons.brightness_auto),
        PickerOption(
            value: ThemeMode.light,
            label: l.themeLight,
            icon: Icons.light_mode),
        PickerOption(
            value: ThemeMode.dark, label: l.themeDark, icon: Icons.dark_mode),
      ],
      onSelected: (mode) => ref.read(themeModeProvider.notifier).select(mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final appLang = ref.watch(localeProvider);
    final aiLang = ref.watch(effectiveAiLangProvider);
    final themeMode = ref.watch(themeModeProvider);
    final source = ref.watch(feedSourceProvider);
    final keyPresent = ref.watch(geminiKeyPresentProvider);
    return Scaffold(
      appBar: AppBar(
        leading: Center(child: Icon(Icons.hub, color: palette.accent)),
        title: Text(l.appTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text(
            l.settingsTitle,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.settingsSubtitle,
            style: TextStyle(fontSize: 15, color: palette.textDim),
          ),
          const SizedBox(height: 24),
          NeonCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.geminiTitle,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l.geminiSubtitle,
                            style:
                                TextStyle(fontSize: 13, color: palette.textDim),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (keyPresent.value ?? false)
                      NeonBadge(label: l.geminiKeySet),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _key,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: l.geminiHint,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                        color: scheme.onSurfaceVariant,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.onAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l.save,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SettingsTile(
            icon: sourceIcon(source),
            title: l.sourceLabel,
            value: source.label,
            accentIcon: true,
            onTap: () => openSourcePicker(context, ref),
          ),
          const SizedBox(height: 16),
          SettingsTile(
            icon: Icons.language,
            title: l.appLanguage,
            value: appLang.nativeLabel,
            onTap: () => _pickAppLanguage(l),
          ),
          const SizedBox(height: 16),
          SettingsTile(
            icon: Icons.translate,
            title: l.aiSummaryLanguage,
            value: aiLang.nativeLabel,
            onTap: () => _pickAiLanguage(l),
          ),
          const SizedBox(height: 16),
          SettingsTile(
            icon: Icons.palette_outlined,
            title: l.theme,
            value: _themeLabel(l, themeMode),
            onTap: () => _pickTheme(l),
          ),
        ],
      ),
    );
  }
}
