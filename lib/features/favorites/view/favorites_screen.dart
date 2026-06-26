import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/topic_chip_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/article.dart';
import '../../feed/view/article_detail_screen.dart';
import '../../search/view/search_screen.dart';
import '../viewmodel/favorites_viewmodel.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesViewModelProvider);
    if (favorites.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l.savedTitle)),
        body: EmptyView(message: l.savedEmpty, asset: AppAnim.savedEmpty),
      );
    }
    final topics = <String>{for (final a in favorites) a.topic}.toList();
    if (_filter != null && !topics.contains(_filter)) _filter = null;
    final shown = _filter == null
        ? favorites
        : favorites.where((a) => a.topic == _filter).toList();
    return Scaffold(
      appBar: AppBar(title: Text(l.savedTitle)),
      body: Column(
        children: [
          const SizedBox(height: 8),
          TopicChipBar(
            allLabel: l.chipAll,
            selected: _filter,
            items: [
              for (final topic in topics)
                TopicChipItem(label: topic, value: topic),
            ],
            onSelected: (value) => setState(() => _filter = value),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(
                top: 4,
                bottom: 64 + MediaQuery.viewPaddingOf(context).bottom + 16,
              ),
              itemCount: shown.length,
              itemBuilder: (_, i) => _SavedCard(article: shown[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedCard extends ConsumerWidget {
  const _SavedCard({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final snippet = Formatters.plainSnippet(article.body);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            _Cover(article: article),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TopicBadge(topic: article.topic),
                      const Spacer(),
                      Icon(Icons.schedule, size: 13, color: palette.textDim),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.timeAgo(
                          article.publishedAt,
                          nowLabel: l.timeNow,
                        ),
                        style: TextStyle(fontSize: 12, color: palette.textDim),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (snippet.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: palette.textDim),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        article.source,
                        style: TextStyle(fontSize: 12, color: palette.textDim),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: l.navSaved,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => ref
                              .read(favoritesViewModelProvider.notifier)
                              .toggle(article),
                          child: Icon(
                            Icons.bookmark,
                            size: 22,
                            color: palette.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    const radius = BorderRadius.vertical(top: Radius.circular(kCardRadius));
    if (article.hasImage) {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: article.imageUrl,
          width: double.infinity,
          height: 160,
          fit: BoxFit.cover,
          memCacheHeight: (160 * dpr).round(),
          errorWidget: (_, _, _) => _faviconCover(palette, radius),
        ),
      );
    }
    return _faviconCover(palette, radius);
  }

  Widget _faviconCover(AppPalette palette, BorderRadius radius) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: palette.iconCircle,
        borderRadius: radius,
        border: Border(bottom: BorderSide(color: palette.mutedBorder)),
      ),
      alignment: Alignment.center,
      child: article.faviconUrl.isEmpty
          ? Icon(Icons.bookmark, size: 40, color: palette.accentText)
          : CachedNetworkImage(
              imageUrl: article.faviconUrl,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              errorWidget: (_, _, _) =>
                  Icon(Icons.bookmark, size: 40, color: palette.accentText),
            ),
    );
  }
}
