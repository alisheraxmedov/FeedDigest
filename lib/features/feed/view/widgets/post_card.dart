import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/neon_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/article.dart';
import '../../../favorites/viewmodel/favorites_viewmodel.dart';
import '../../../summary/view/summary_sheet.dart';
import '../../viewmodel/read_state_viewmodel.dart';
import '../article_detail_screen.dart';
import 'post_image.dart';

/// The feed card: a source-identified header, the title, an optional dev.to
/// cover (link posts show their host instead), then metrics, an AI-summary pill
/// and the bookmark toggle.
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
    // Reading-time badge only when there's enough body to estimate from.
    final readMins = article.body.trim().length > 80
        ? Formatters.readingMinutes(article.body)
        : null;
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
          radius: 22,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(article: article),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(14, 14, 14, article.hasImage ? 12 : 0),
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
                        fontSize: 16,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (!article.hasImage) ...[
                      const SizedBox(height: 10),
                      _LinkHostRow(host: article.linkHost),
                    ],
                  ],
                ),
              ),
              if (article.hasImage)
                PostCover(
                  article: article,
                  height: 132,
                  borderRadius: BorderRadius.zero,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
                child: Row(
                  children: [
                    _Metric(
                      icon: _isHackerNews
                          ? Icons.arrow_upward
                          : Icons.favorite_border,
                      value: Formatters.compactScore(article.score),
                    ),
                    const SizedBox(width: 14),
                    _Metric(
                      icon: Icons.chat_bubble_outline,
                      value: Formatters.compactScore(article.commentCount),
                    ),
                    if (readMins != null) ...[
                      const SizedBox(width: 14),
                      _Metric(
                        icon: Icons.schedule,
                        value: l.readingTime(readMins),
                      ),
                    ],
                    const Spacer(),
                    AiPill(
                      label: 'AI',
                      onTap: () => showSummarySheet(context, article),
                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header row: a source-tinted avatar tile, the poster + `source · time`, and
/// the topic tag on the right.
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
        _Avatar(article: article, name: name),
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
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${article.source} · $when',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: palette.textDim),
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

/// 38px rounded-11 avatar tile. dev.to posts show the author monogram on the
/// purple brand gradient; Hacker News shows its orange tile.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.article, required this.name});

  final Article article;
  final String name;

  bool get _isHackerNews => article.source.toLowerCase().contains('hacker');

  String get _monogram {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '#' : trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const size = 38.0;
    final decoration = _isHackerNews
        ? const BoxDecoration(
            color: AppColors.hackerNewsOrange,
            borderRadius: BorderRadius.all(Radius.circular(11)),
          )
        : const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.devtoAvatarStart, AppColors.devtoAvatarEnd],
            ),
            borderRadius: BorderRadius.all(Radius.circular(11)),
          );
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: decoration,
      child: Text(
        _isHackerNews ? 'Y' : _monogram,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Compact host line shown on link posts (Hacker News) in place of a cover.
class _LinkHostRow extends StatelessWidget {
  const _LinkHostRow({required this.host});

  final String host;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    if (host.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.link, size: 14, color: palette.textDim),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            host,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: palette.textDim),
          ),
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
    final palette = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: palette.textDim),
        const SizedBox(width: 5),
        Text(value, style: TextStyle(fontSize: 12.5, color: palette.textDim)),
      ],
    );
  }
}
