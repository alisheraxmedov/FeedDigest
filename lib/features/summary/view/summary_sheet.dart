import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/prefs/preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../core/widgets/read_aloud_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/gemini_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/article.dart';
import '../../settings/view/settings_screen.dart';
import '../viewmodel/summary_viewmodel.dart';

Future<void> showSummarySheet(BuildContext context, Article article) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => SummarySheet(article: article),
  );
}

class SummarySheet extends ConsumerWidget {
  const SummarySheet({super.key, required this.article});

  final Article article;

  String _errorText(Object error, AppLocalizations l) {
    if (error is GeminiException) {
      if (error.code == 'no_key') return l.summaryNoKey;
      if (error.code == 'blocked') return l.summaryBlocked;
    }
    return l.summaryFailed;
  }

  /// Missing key isn't retryable — route the user to Settings to add one.
  /// Every other error keeps the normal retry affordance.
  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    Object error,
  ) {
    final noKey = error is GeminiException && error.code == 'no_key';
    if (!noKey) {
      return ErrorView(
        compact: true,
        message: _errorText(error, l),
        onRetry: () => ref.invalidate(summaryViewModelProvider(article)),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l.summaryNoKey,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        NeonButton(
          label: l.summaryAddKey,
          icon: Icons.key,
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final summary = ref.watch(summaryViewModelProvider(article));
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedAiMagic,
                  color: palette.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  l.aiSummary.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: palette.accentText,
                  ),
                ),
                const Spacer(),
                if (summary.value != null && summary.value!.isNotEmpty)
                  ReadAloudButton(
                    text: summary.value!,
                    langCode: ref.watch(effectiveAiLangProvider).code,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              article.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 19,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            const _DepthToggle(),
            const SizedBox(height: 16),
            Flexible(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 96),
                padding: const EdgeInsets.all(16),
                child: summary.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LoadingView(asset: AppAnim.aiThinking, size: 140),
                  ),
                  error: (e, _) => _buildError(context, ref, l, e),
                  data: (text) => SingleChildScrollView(
                    child: MarkdownBody(
                      data: text,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 16,
                          height: 1.55,
                          color: scheme.onSurface,
                        ),
                        h2: TextStyle(
                          fontSize: 18,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                        h3: TextStyle(
                          fontSize: 17,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                        strong: const TextStyle(fontWeight: FontWeight.w700),
                        listBullet: TextStyle(
                          fontSize: 16,
                          height: 1.55,
                          color: scheme.onSurface,
                        ),
                      ),
                      selectable: true,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            NeonButton(
              label: l.close,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-segment control for the AI summary length (Brief ↔ Detailed). Writes to
/// [summaryDepthProvider]; the view model watches it and re-summarizes (or hits
/// the depth-keyed cache) when it flips.
class _DepthToggle extends ConsumerWidget {
  const _DepthToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final current = ref.watch(summaryDepthProvider);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.iconCircle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.mutedBorder),
      ),
      child: Row(
        children: [
          _segment(
            ref,
            palette,
            l.summaryDepthBrief,
            SummaryDepth.brief,
            current,
          ),
          _segment(
            ref,
            palette,
            l.summaryDepthDetailed,
            SummaryDepth.detailed,
            current,
          ),
        ],
      ),
    );
  }

  Widget _segment(
    WidgetRef ref,
    AppPalette palette,
    String label,
    SummaryDepth value,
    SummaryDepth current,
  ) {
    final selected = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: selected
            ? null
            : () => ref.read(summaryDepthProvider.notifier).select(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? palette.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? palette.accentText : palette.textDim,
            ),
          ),
        ),
      ),
    );
  }
}
