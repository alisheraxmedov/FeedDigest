import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/article.dart';
import '../../feed/view/article_detail_screen.dart';
import '../../feed/view/widgets/post_image.dart';
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
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _SavedHeader(count: 0),
              Expanded(
                child: EmptyView(message: l.savedEmpty, asset: AppAnim.savedEmpty),
              ),
            ],
          ),
        ),
      );
    }
    final topics = <String>{for (final a in favorites) a.topic}.toList();
    if (_filter != null && !topics.contains(_filter)) _filter = null;
    final shown = _filter == null
        ? favorites
        : favorites.where((a) => a.topic == _filter).toList();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SavedHeader(count: favorites.length),
            _TopicFilterRow(
              topics: topics,
              filter: _filter,
              onSelected: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: 6),
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
      ),
    );
  }
}

/// Screen title ("Saved", 27 Outfit 700) with a muted count line derived from
/// the current favorites length.
class _SavedHeader extends StatelessWidget {
  const _SavedHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.savedTitle,
            style: GoogleFonts.outfit(
              fontSize: 27,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.1,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$count ${l.navSaved.toLowerCase()}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: palette.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single horizontal row of topic filter pills (radius 11). "All" clears the
/// filter; each topic chip drives the same `_filter` state as before.
class _TopicFilterRow extends StatelessWidget {
  const _TopicFilterRow({
    required this.topics,
    required this.filter,
    required this.onSelected,
  });

  final List<String> topics;
  final String? filter;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CategoryChip(
              label: l.chipAll,
              selected: filter == null,
              radius: 11,
              onTap: () => onSelected(null),
            ),
          ),
          for (final topic in topics)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CategoryChip(
                label: topic,
                selected: filter == topic,
                radius: 11,
                onTap: () => onSelected(topic),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact, denser saved card: a 58px thumbnail, a source-dot meta line, a
/// two-line title, and a filled accent bookmark that removes the article.
class _SavedCard extends ConsumerWidget {
  const _SavedCard({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final metaStyle = TextStyle(fontSize: 11.5, color: palette.textDim);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: NeonCard(
        radius: 18,
        padding: const EdgeInsets.all(10),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(article: article),
          ),
        ),
        child: Row(
          children: [
            PostImage(article: article, size: 58),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SourceDot(article: article),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          article.source,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: metaStyle.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text('  ·  ', style: metaStyle),
                      Text(
                        Formatters.timeAgo(
                          article.publishedAt,
                          nowLabel: l.timeNow,
                        ),
                        style: metaStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: l.navSaved,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () =>
                    ref.read(favoritesViewModelProvider.notifier).toggle(article),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.bookmark, size: 22, color: palette.accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small colored dot flagging the article's source: solid orange for Hacker
/// News, the dev.to violet gradient otherwise.
class _SourceDot extends StatelessWidget {
  const _SourceDot({required this.article});

  final Article article;

  bool get _isHackerNews => article.source.toLowerCase().contains('hacker');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: _isHackerNews
          ? const BoxDecoration(
              color: AppColors.hackerNewsOrange,
              shape: BoxShape.circle,
            )
          : const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.devtoAvatarStart, AppColors.devtoAvatarEnd],
              ),
            ),
    );
  }
}
