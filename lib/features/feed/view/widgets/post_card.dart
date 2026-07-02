import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/neon_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/article.dart';
import '../../../favorites/viewmodel/favorites_viewmodel.dart';
import '../../viewmodel/read_state_viewmodel.dart';
import '../article_detail_screen.dart';
import 'post_image.dart';

/// The feed card, LinkedIn-style: a full-width cover, an author + time header,
/// the title, a body snippet, then the topic tag and engagement metrics.
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
    // Link posts (e.g. most Hacker News stories) carry no body text; fall back
    // to the destination host so the card never renders an empty gap.
    final bodySnippet = Formatters.plainSnippet(article.body);
    final snippet = bodySnippet.isNotEmpty ? bodySnippet : article.linkHost;
    final isRead = ref.watch(
      readStateProvider.select((ids) => ids.contains(article.id)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: AnimatedOpacity(
        opacity: isRead ? 0.6 : 1,
        duration: const Duration(milliseconds: 200),
        child: NeonCard(
          padding: EdgeInsets.zero,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(article: article),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header + title above the cover.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AuthorRow(article: article),
                    const SizedBox(height: 12),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 19,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              // Full-bleed cover between the title and the body snippet.
              PostCover(article: article, borderRadius: BorderRadius.zero),
              // Snippet + engagement metrics below the cover.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (snippet.isNotEmpty) ...[
                      Text(
                        snippet,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: palette.textDim,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
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
                            color: isFav
                                ? palette.accent
                                : scheme.onSurfaceVariant,
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
            ],
          ),
        ),
      ),
    );
  }
}

/// LinkedIn-style header: domain avatar, who posted it and when, topic tag.
class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final name = article.author.isNotEmpty ? article.author : article.source;
    final when = Formatters.timeAgo(article.publishedAt, nowLabel: l.timeNow);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Avatar(article: article),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${article.source} · $when',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: palette.textDim),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TopicBadge(topic: article.topic),
      ],
    );
  }
}

/// Circular domain favicon shown next to the author name.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    const size = 40.0;
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    final fallback = Icon(
      Icons.person_outline,
      size: 20,
      color: palette.accentText,
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.iconCircle,
        shape: BoxShape.circle,
        border: Border.all(color: palette.mutedBorder),
      ),
      child: article.faviconUrl.isEmpty
          ? fallback
          : CachedNetworkImage(
              imageUrl: article.faviconUrl,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              memCacheWidth: px,
              memCacheHeight: px,
              errorWidget: (_, _, _) => fallback,
            ),
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
