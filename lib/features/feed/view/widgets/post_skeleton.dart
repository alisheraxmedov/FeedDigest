import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Placeholder feed that mirrors the [PostCard] shape while articles load: an
/// avatar + header lines, a full-bleed cover, then title and body lines — each a
/// shimmering bar swept left→right by a single repeating controller.
class PostSkeleton extends StatefulWidget {
  const PostSkeleton({super.key});

  @override
  State<PostSkeleton> createState() => _PostSkeletonState();
}

class _PostSkeletonState extends State<PostSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) => _SkeletonCard(t: _controller.value),
        ),
      ),
    );
  }
}

/// One skeleton card. Rebuilt each frame with the current sweep phase [t].
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.t});

  /// Shimmer sweep phase, 0→1.
  final double t;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF152128) : const Color(0xFFE9F0F1);
    final highlight = isDark ? const Color(0xFF1C2A31) : const Color(0xFFF5FAFB);

    Widget bar({required double height, double radius = 6}) =>
        _ShimmerBar(t: t, base: base, highlight: highlight, height: height, radius: radius);

    // A left-aligned bar spanning [fill]% of the available width.
    Widget line(int fill, {required double height, double radius = 6}) {
      final rowBar = bar(height: height, radius: radius);
      if (fill >= 100) return rowBar;
      return Row(
        children: [
          Expanded(flex: fill, child: rowBar),
          Expanded(flex: 100 - fill, child: const SizedBox.shrink()),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: palette.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.mutedBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar block + two short header lines.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: bar(height: 38, radius: 11),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      line(52, height: 11),
                      const SizedBox(height: 8),
                      line(32, height: 9),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Full-bleed cover.
          bar(height: 132, radius: 0),
          // Title lines + body lines.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                line(95, height: 13),
                const SizedBox(height: 10),
                line(68, height: 13),
                const SizedBox(height: 16),
                line(100, height: 10),
                const SizedBox(height: 8),
                line(55, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single shimmering bar: a rounded rectangle whose 3-stop gradient is
/// translated across its width by [t] to fake a moving highlight.
class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({
    required this.t,
    required this.base,
    required this.highlight,
    required this.height,
    this.radius = 6,
  });

  final double t;
  final Color base;
  final Color highlight;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [base, highlight, base],
          stops: const [0.25, 0.5, 0.75],
          transform: _SlideGradientTransform(t),
        ),
      ),
    );
  }
}

/// Slides a gradient horizontally from fully off the left edge to fully off the
/// right edge as [t] runs 0→1, so its bright middle stop sweeps across the bar.
class _SlideGradientTransform extends GradientTransform {
  const _SlideGradientTransform(this.t);

  final double t;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues((t * 2 - 1) * bounds.width, 0, 0);
  }
}
