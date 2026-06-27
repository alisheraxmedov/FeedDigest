import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Lottie illustration assets bundled under `assets/lottie/`. Centralised here so
/// every state view and caller references the same paths.
class AppAnim {
  AppAnim._();
  static const _dir = 'assets/lottie';

  static const loading = '$_dir/loading.json';
  static const aiThinking = '$_dir/ai_thinking.json';
  static const error = '$_dir/error_state.json';
  static const feedEmpty = '$_dir/feed_empty.json';
  static const searchEmpty = '$_dir/search_empty.json';
  static const savedEmpty = '$_dir/saved_empty.json';
}

/// Centered Lottie loader. Defaults to the generic glow loader; sheets can swap
/// in a themed animation (e.g. the AI "thinking" loop) via [asset].
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.asset = AppAnim.loading, this.size = 120});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) => Center(
        child: Lottie.asset(
          asset,
          width: size,
          height: size,
          repeat: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
}

/// Error state: a Lottie illustration, a muted message and an optional retry
/// action. [compact] shrinks the animation for use inside bottom sheets.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              AppAnim.error,
              width: compact ? 120 : 160,
              height: compact ? 120 : 160,
              repeat: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.4, color: palette.textDim),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.onAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(AppLocalizations.of(context).retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state: a Lottie illustration with an Outfit title and an optional
/// muted subtitle. Callers pass the matching [asset] (feed / search / saved).
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.subtitle,
    this.asset = AppAnim.feedEmpty,
    this.animationSize = 160,
  });

  final String message;
  final String? subtitle;
  final String asset;
  final double animationSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              asset,
              width: animationSize,
              height: animationSize,
              repeat: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.4, color: palette.textDim),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
