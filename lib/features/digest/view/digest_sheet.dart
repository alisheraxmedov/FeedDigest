/*
DigestSheet shows the AI-generated "today's top stories" digest in a bottom
sheet. It mirrors the single-article summary sheet: a loading animation while
Gemini works, a Markdown body when it lands, and a routed "add key" CTA when the
user hasn't set a Gemini key yet.
*/
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/gemini_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/view/settings_screen.dart';
import '../viewmodel/digest_viewmodel.dart';

Future<void> showDigestSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const DigestSheet(),
  );
}

class DigestSheet extends ConsumerWidget {
  const DigestSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final digest = ref.watch(digestViewModelProvider);
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
                  icon: HugeIcons.strokeRoundedNews,
                  color: palette.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  l.digestTitle.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: palette.accentText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 96),
                padding: const EdgeInsets.all(16),
                child: digest.when(
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
                          fontSize: 20,
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

  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    Object error,
  ) {
    if (error is GeminiException && error.code == 'empty') {
      return EmptyView(message: l.feedEmpty, animationSize: 120);
    }
    final noKey = error is GeminiException && error.code == 'no_key';
    if (!noKey) {
      return ErrorView(
        compact: true,
        message: l.summaryFailed,
        onRetry: () => ref.invalidate(digestViewModelProvider),
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
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }
}
