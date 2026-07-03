import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/prefs/preferences.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../favorites/viewmodel/favorites_viewmodel.dart';
import '../../feed/view/widgets/source_switcher.dart';
import '../../feed/viewmodel/feed_source_viewmodel.dart';
import '../../subscriptions/viewmodel/subscriptions_viewmodel.dart';
import '../viewmodel/settings_viewmodel.dart';
import 'widgets/notification_settings_sheet.dart';

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
    final l = AppLocalizations.of(context);
    try {
      await ref.read(settingsActionsProvider).saveKey(_key.text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.keySaveFailed)));
      return;
    }
    if (!mounted) return;
    _key.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.keySaved)));
  }

  Future<void> _exportData() async {
    final l = AppLocalizations.of(context);
    final subs = ref.read(subscriptionsViewModelProvider);
    final favs = ref.read(favoritesViewModelProvider);
    try {
      await ref
          .read(exportServiceProvider)
          .shareBackup(
            subscriptions: subs,
            favorites: favs,
            nowMs: DateTime.now().millisecondsSinceEpoch,
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.exportFailed)));
    }
  }

  void _pickAppLanguage(AppLocalizations l) {
    showOptionPicker<AppLanguage>(
      context: context,
      title: l.appLanguage,
      selected: ref.read(localeProvider),
      options: [
        for (final lang in AppLanguage.values)
          PickerOption(
            value: lang,
            label: lang.nativeLabel,
            icon: Icons.language,
          ),
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
          PickerOption(
            value: lang,
            label: lang.nativeLabel,
            icon: Icons.translate,
          ),
      ],
      onSelected: (lang) =>
          ref.read(aiSummaryLangProvider.notifier).select(lang),
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
    final notif = ref.watch(notificationPrefsProvider);
    return Scaffold(
      appBar: AppBar(
        // As a tab this shows the app icon; when pushed as a route (e.g. from
        // the "add key" shortcut in chat) it becomes a back button so the user
        // is never stranded.
        leading: Navigator.of(context).canPop()
            ? const BackButton()
            : Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.asset(
                    'assets/icons/feeddigest-1b-monogram-f.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
        title: Text(l.appTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text(
            l.settingsTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 27,
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
          _GeminiKeyCard(
            controller: _key,
            obscure: _obscure,
            keyPresent: keyPresent.value ?? false,
            onToggleObscure: () => setState(() => _obscure = !_obscure),
            onSave: _save,
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Content'),
          _GroupCard(
            children: [
              _GroupTile(
                icon: sourceIcon(source),
                title: l.sourceLabel,
                value: source.label,
                accentIcon: true,
                onTap: () => openSourcePicker(context, ref),
              ),
              _GroupTile(
                icon: Icons.language,
                title: l.appLanguage,
                value: appLang.nativeLabel,
                onTap: () => _pickAppLanguage(l),
              ),
              _GroupTile(
                icon: Icons.translate,
                title: l.aiSummaryLanguage,
                value: aiLang.nativeLabel,
                onTap: () => _pickAiLanguage(l),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Appearance'),
          BrandSegmented<ThemeMode>(
            selected: themeMode,
            onChanged: (mode) =>
                ref.read(themeModeProvider.notifier).select(mode),
            options: [
              SegmentOption(
                value: ThemeMode.system,
                label: l.themeSystem,
                icon: Icons.brightness_auto,
              ),
              SegmentOption(
                value: ThemeMode.light,
                label: l.themeLight,
                icon: Icons.light_mode,
              ),
              SegmentOption(
                value: ThemeMode.dark,
                label: l.themeDark,
                icon: Icons.dark_mode,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Data'),
          _GroupCard(
            children: [
              _GroupTile(
                icon: Icons.notifications_none,
                title: l.notifDigestLabel,
                value: notif.enabled ? notif.hhmm : l.notifOff,
                accentIcon: true,
                onTap: () => showNotificationSettingsSheet(context),
              ),
              _GroupTile(
                icon: Icons.ios_share,
                title: l.exportData,
                value: l.exportDataDesc,
                onTap: _exportData,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The Gemini API-key card: a gradient spark tile, status pill, obscured key
/// field with a show/hide toggle, and the gradient "Save key" button. Purely
/// presentational — the caller supplies the controller and handlers.
class _GeminiKeyCard extends StatelessWidget {
  const _GeminiKeyCard({
    required this.controller,
    required this.obscure,
    required this.keyPresent,
    required this.onToggleObscure,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool obscure;
  final bool keyPresent;
  final VoidCallback onToggleObscure;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return NeonCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GradientSparkTile(
                icon: Icons.auto_awesome,
                size: 34,
                radius: 11,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.geminiTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _KeyStatusPill(present: keyPresent),
            ],
          ),
          const SizedBox(height: 13),
          TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(color: scheme.onSurface, fontSize: 15),
            decoration: InputDecoration(
              isDense: true,
              hintText: l.geminiHint,
              hintStyle: TextStyle(color: palette.textDim),
              filled: true,
              fillColor: palette.inputFill,
              contentPadding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.mutedBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.mutedBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.accent, width: 1.5),
              ),
              suffixIcon: IconButton(
                iconSize: 20,
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: palette.textDim,
                ),
                onPressed: onToggleObscure,
              ),
            ),
          ),
          const SizedBox(height: 12),
          NeonButton(label: l.save, onPressed: onSave, height: 44, radius: 12),
        ],
      ),
    );
  }
}

/// Compact key-status pill: accent dot + "Set" when a key exists, a muted dot
/// + "Not set" otherwise.
class _KeyStatusPill extends StatelessWidget {
  const _KeyStatusPill({required this.present});

  final bool present;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final color = present ? palette.accentText : palette.textDim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: present ? palette.accentSoft : palette.iconCircle,
        borderRadius: BorderRadius.circular(999),
        border: present ? null : Border.all(color: palette.mutedBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            present ? l.geminiKeySet : l.geminiKeyNotSet,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Uppercase section label (11.5 Inter 700, +0.7 tracking, textDim).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: palette.textDim,
        ),
      ),
    );
  }
}

/// One grouped card (cardColor, border, radius 20) holding [children] rows with
/// hairline dividers between them.
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: palette.mutedBorder,
          ),
        );
      }
      rows.add(children[i]);
    }
    return NeonCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Column(children: rows),
      ),
    );
  }
}

/// A single divided row inside a [_GroupCard]: icon tile + title + current value
/// + chevron. Mirrors [SettingsTile] but renders inline (no per-row card).
class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.accentIcon = false,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;
  final bool accentIcon;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconCircle(icon: icon, accent: accentIcon, radius: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (value != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        value!,
                        style: TextStyle(fontSize: 13, color: palette.textDim),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
