/*
PostImage is the square thumbnail on a card. dev.to articles have a cover image,
shown cropped to fill the box; Hacker News has none, so the article domain's
favicon is shown centered in a tinted box with a neon-tinted icon fallback.
*/
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/article.dart';

class PostImage extends StatelessWidget {
  const PostImage({super.key, required this.article, this.size = 72});

  final Article article;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    if (article.hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: article.imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _favicon(context, palette),
        ),
      );
    }
    return _favicon(context, palette);
  }

  Widget _favicon(BuildContext context, AppPalette palette) {
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
              errorWidget: (_, _, _) => fallback,
            ),
    );
  }
}
