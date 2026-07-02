/*
Bottom sheet to enable the daily digest reminder and pick its time. Enabling
requests OS notification permission first; every change is persisted and the OS
schedule is (re)armed via NotificationService with localized text.
*/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/prefs/preferences.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

Future<void> showNotificationSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const NotificationSettingsSheet(),
  );
}

class NotificationSettingsSheet extends ConsumerStatefulWidget {
  const NotificationSettingsSheet({super.key});

  @override
  ConsumerState<NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends ConsumerState<NotificationSettingsSheet> {
  Future<void> _reschedule(NotificationPrefs prefs) async {
    final l = AppLocalizations.of(context);
    if (prefs.enabled) {
      await NotificationService.instance.scheduleDaily(
        hour: prefs.hour,
        minute: prefs.minute,
        title: l.appTitle,
        body: l.notifBody,
      );
    } else {
      await NotificationService.instance.cancelDaily();
    }
  }

  Future<void> _toggle(bool value) async {
    final l = AppLocalizations.of(context);
    final ctrl = ref.read(notificationPrefsProvider.notifier);
    final prefs = ref.read(notificationPrefsProvider);
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.notifDenied)),
          );
        }
        return;
      }
    }
    final updated = prefs.copyWith(enabled: value);
    await ctrl.save(updated);
    await _reschedule(updated);
  }

  Future<void> _pickTime() async {
    final prefs = ref.read(notificationPrefsProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: prefs.hour, minute: prefs.minute),
    );
    if (picked == null) return;
    final updated = prefs.copyWith(hour: picked.hour, minute: picked.minute);
    await ref.read(notificationPrefsProvider.notifier).save(updated);
    await _reschedule(updated);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final prefs = ref.watch(notificationPrefsProvider);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: palette.mutedBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              l.notifDigestLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.notifDigestDesc,
              style: TextStyle(fontSize: 13, color: palette.textDim),
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeTrackColor: palette.accent,
              title: Text(
                l.notifDigestLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              value: prefs.enabled,
              onChanged: _toggle,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: prefs.enabled,
              leading: Icon(
                Icons.schedule,
                color: prefs.enabled ? palette.accent : palette.textDim,
              ),
              title: Text(
                l.notifTimeLabel,
                style: TextStyle(
                  fontSize: 16,
                  color: prefs.enabled ? scheme.onSurface : palette.textDim,
                ),
              ),
              trailing: Text(
                prefs.hhmm,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: prefs.enabled ? palette.accentText : palette.textDim,
                ),
              ),
              onTap: prefs.enabled ? _pickTime : null,
            ),
          ],
        ),
      ),
    );
  }
}
