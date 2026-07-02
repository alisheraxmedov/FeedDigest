/*
Bottom sheet to adjust the article reading text size. Writes to
readerTextScaleProvider; the detail screen composes this with the system text
scale so the whole article reflows live.
*/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/prefs/preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

Future<void> showReaderSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (_) => const ReaderSettingsSheet(),
  );
}

class ReaderSettingsSheet extends ConsumerWidget {
  const ReaderSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final scale = ref.watch(readerTextScaleProvider);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.readerText,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.readerTextSample,
              style: TextStyle(
                fontSize: 16 * scale,
                height: 1.5,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'A',
                  style: TextStyle(fontSize: 14, color: palette.textDim),
                ),
                Expanded(
                  child: Slider(
                    value: scale,
                    min: ReaderTextScaleController.minScale,
                    max: ReaderTextScaleController.maxScale,
                    divisions: 5,
                    activeColor: palette.accent,
                    label: '${(scale * 100).round()}%',
                    onChanged: (v) =>
                        ref.read(readerTextScaleProvider.notifier).set(v),
                  ),
                ),
                Text(
                  'A',
                  style: TextStyle(fontSize: 24, color: palette.textDim),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
