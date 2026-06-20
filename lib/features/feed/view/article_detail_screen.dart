/*
ArticleDetailScreen is the in-app reading page opened when a card is tapped. It
shows a hero image (dev.to cover) or a favicon banner (Hacker News), the source
and topic, the title, author and engagement metadata, the article body, and two
actions: open the original article and request an AI summary.
*/
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/article.dart';
import '../../favorites/viewmodel/favorites_viewmodel.dart';
import '../../summary/view/summary_sheet.dart';

class ArticleDetailScreen extends ConsumerWidget {
  const ArticleDetailScreen({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    ref.watch(favoritesViewModelProvider);
    final isFav =
        ref.read(favoritesViewModelProvider.notifier).isFavorite(article.id);
    final body = article.body
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return Scaffold(
      appBar: AppBar(
        title: Text(article.source),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? palette.accent : scheme.onSurface,
            ),
            onPressed: () =>
                ref.read(favoritesViewModelProvider.notifier).toggle(article),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _Banner(article: article),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopicLine(article: article),
                const SizedBox(height: 12),
                Text(
                  article.title,
                  style: TextStyle(
                    fontSize: 26,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _AuthorRow(article: article),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.55,
                      color: scheme.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                NeonButton(
                  label: l.openOriginal,
                  uppercase: true,
                  icon: Icons.open_in_new,
                  onPressed: () => launchUrl(
                    Uri.parse(article.link),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const SizedBox(height: 12),
                NeonGhostButton(
                  label: l.aiSummary,
                  uppercase: true,
                  icon: Icons.auto_awesome,
                  onPressed: () => showSummarySheet(context, article),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: article.hasImage
            ? CachedNetworkImage(
                imageUrl: article.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _faviconBanner(palette),
              )
            : _faviconBanner(palette),
      ),
    );
  }

  Widget _faviconBanner(AppPalette palette) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: palette.iconCircle,
        border: Border.all(color: palette.mutedBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: article.faviconUrl.isEmpty
          ? Icon(Icons.article_outlined, size: 48, color: palette.accentText)
          : CachedNetworkImage(
              imageUrl: article.faviconUrl,
              width: 56,
              height: 56,
              fit: BoxFit.contain,
              errorWidget: (_, _, _) =>
                  Icon(Icons.article_outlined, size: 48, color: palette.accentText),
            ),
    );
  }
}

class _TopicLine extends StatelessWidget {
  const _TopicLine({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          article.source,
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: 8),
        Container(
          width: 3,
          height: 3,
          decoration:
              BoxDecoration(color: palette.mutedBorder, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '#${article.topic}',
          style: TextStyle(fontSize: 13, color: palette.accentText),
        ),
      ],
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final meta = [
      if (article.author.isNotEmpty) '@${article.author}',
      Formatters.timeAgo(article.publishedAt, nowLabel: l.timeNow),
    ].join('  ·  ');
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration:
              BoxDecoration(color: palette.iconCircle, shape: BoxShape.circle),
          child: Icon(Icons.person, size: 20, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            meta,
            style: TextStyle(fontSize: 13, color: palette.textDim),
          ),
        ),
        Icon(Icons.arrow_upward, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          Formatters.compactScore(article.score),
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Icon(Icons.chat_bubble_outline, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          Formatters.compactScore(article.commentCount),
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
