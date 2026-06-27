import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/neon_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/article.dart';
import '../../../favorites/viewmodel/favorites_viewmodel.dart';
import '../article_detail_screen.dart';
import 'post_image.dart';

class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.article});

  final Article article;

  bool get _isHackerNews => article.source.toLowerCase().contains('hacker');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isFav = ref.watch(
      favoritesViewModelProvider.select(
        (favs) => favs.any((a) => a.id == article.id),
      ),
    );
    final hasThumb = article.hasImage || article.faviconUrl.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: NeonCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(article: article),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MetaRow(article: article),
                      const SizedBox(height: 6),
                      Text(
                        article.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 19,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasThumb) ...[
                  const SizedBox(width: 16),
                  PostImage(article: article),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Metric(
                  icon: _isHackerNews
                      ? Icons.arrow_upward
                      : Icons.favorite_border,
                  value: Formatters.compactScore(article.score),
                ),
                const SizedBox(width: 16),
                _Metric(
                  icon: Icons.chat_bubble_outline,
                  value: Formatters.compactScore(article.commentCount),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: l.navSaved,
                  icon: Icon(
                    isFav ? Icons.bookmark : Icons.bookmark_border,
                    size: 22,
                    color: isFav ? palette.accent : scheme.onSurfaceVariant,
                  ),
                  onPressed: () => ref
                      .read(favoritesViewModelProvider.notifier)
                      .toggle(article),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dim = TextStyle(fontSize: 13, color: scheme.onSurfaceVariant);
    Widget dot() => Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: palette.mutedBorder,
        shape: BoxShape.circle,
      ),
    );
    return Row(
      children: [
        Flexible(
          child: Text(
            article.source,
            style: dim,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        dot(),
        Flexible(
          child: Text(
            '#${article.topic}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: palette.accentText.withValues(alpha: 0.8),
            ),
          ),
        ),
        dot(),
        Text(
          Formatters.timeAgo(article.publishedAt, nowLabel: l.timeNow),
          style: dim,
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
