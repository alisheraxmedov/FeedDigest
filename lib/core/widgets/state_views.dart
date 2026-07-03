import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'neon_widgets.dart';

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
      errorBuilder: (_, _, _) =>
          const Center(child: CircularProgressIndicator()),
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
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: palette.textDim,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.onAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
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

/// Empty state: by default an accentSoft icon circle with an overlapping spark
/// badge, an Outfit title, an optional muted subtitle and an optional gradient
/// CTA. Callers that pass a Lottie [asset] keep the illustrated treatment.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.asset,
    this.animationSize = 160,
    this.onAction,
    this.actionLabel,
  });

  final String message;
  final String? subtitle;

  /// Line icon shown inside the accentSoft circle when no [asset] is supplied.
  /// Callers pass e.g. a bookmark (Saved) or a magnifier (Search).
  final IconData icon;

  /// Optional Lottie illustration. When null the circular-icon treatment (the
  /// redesign default) is shown instead.
  final String? asset;
  final double animationSize;

  /// Optional gradient call-to-action, rendered only when both are provided.
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);
    final asset = this.asset;
    final actionLabel = this.actionLabel;
    final visual = asset != null
        ? Lottie.asset(
            asset,
            width: animationSize,
            height: animationSize,
            repeat: true,
            errorBuilder: (_, _, _) => _IconBadge(icon: icon),
          )
        : _IconBadge(icon: icon);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            visual,
            const SizedBox(height: 22),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 19,
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: palette.textDim,
                ),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: NeonButton(label: actionLabel, onPressed: onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A 96px accentSoft circle holding a line [icon], with a small brand-gradient
/// spark tile overlapping its top-right corner.
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.accentSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 40, color: palette.accentText),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const GradientSparkTile(
              icon: Icons.auto_awesome,
              size: 30,
              radius: 10,
            ),
          ),
        ),
      ],
    );
  }
}
