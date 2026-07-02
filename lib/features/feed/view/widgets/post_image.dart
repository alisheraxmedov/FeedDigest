/*
PostImage is the square thumbnail on a card. dev.to articles have a cover image,
shown cropped to fill the box; Hacker News has none, so the article domain's
favicon is shown centered in a tinted box with a neon-tinted icon fallback.
*/
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/neon_widgets.dart';
import '../../../../models/article.dart';

class PostImage extends StatelessWidget {
  const PostImage({super.key, required this.article, this.size = 72});

  final Article article;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    // Decode to the box's pixel size, not the source resolution. A 72pt thumb on
    // a 3x screen needs ~216px; a 1200px source otherwise wastes ~30x the RAM.
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    if (article.hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: article.imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: px,
          memCacheHeight: px,
          errorWidget: (_, _, _) => _favicon(context, palette, px),
        ),
      );
    }
    return _favicon(context, palette, px);
  }

  Widget _favicon(BuildContext context, AppPalette palette, int px) {
    final fallback = Icon(Icons.data_object, color: palette.accentText);
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.iconCircle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.mutedBorder),
      ),
      child: article.faviconUrl.isEmpty
          ? fallback
          : CachedNetworkImage(
              imageUrl: article.faviconUrl,
              fit: BoxFit.contain,
              memCacheWidth: px,
              memCacheHeight: px,
              errorWidget: (_, _, _) => fallback,
            ),
    );
  }
}

/// PostCover is the full-width, LinkedIn-style banner at the top of a feed card.
/// dev.to covers fill edge-to-edge; Hacker News has no image, so a shorter
/// tinted band shows the domain favicon (or a neon icon) centered.
class PostCover extends StatelessWidget {
  const PostCover({
    super.key,
    required this.article,
    this.height = 200,
    this.borderRadius = _topRounded,
  });

  final Article article;
  final double height;

  /// Corner rounding. Defaults to top-only (card header); pass [BorderRadius.zero]
  /// when the cover sits mid-card between the title and the body snippet.
  final BorderRadius borderRadius;

  static const _topRounded = BorderRadius.vertical(
    top: Radius.circular(kCardRadius),
  );

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    if (article.hasImage) {
      // Decode to the band height in device pixels, not the source resolution.
      final ph = (height * MediaQuery.devicePixelRatioOf(context)).round();
      return ClipRRect(
        borderRadius: borderRadius,
        child: CachedNetworkImage(
          imageUrl: article.imageUrl,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          memCacheHeight: ph,
          errorWidget: (_, _, _) => _fallback(palette),
        ),
      );
    }
    return _fallback(palette);
  }

  Widget _fallback(AppPalette palette) {
    final icon = Icon(Icons.data_object, size: 44, color: palette.accentText);
    return Container(
      width: double.infinity,
      height: height * 0.62,
      decoration: BoxDecoration(
        color: palette.iconCircle,
        borderRadius: borderRadius,
        border: Border.symmetric(
          horizontal: BorderSide(color: palette.mutedBorder),
        ),
      ),
      alignment: Alignment.center,
      child: article.faviconUrl.isEmpty
          ? icon
          : CachedNetworkImage(
              imageUrl: article.faviconUrl,
              width: 52,
              height: 52,
              fit: BoxFit.contain,
              errorWidget: (_, _, _) => icon,
            ),
    );
  }
}
