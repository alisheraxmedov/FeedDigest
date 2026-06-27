import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/article.dart';
import '../../feed/view/article_detail_screen.dart';
import '../../feed/view/widgets/post_image.dart';
import '../viewmodel/search_viewmodel.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String query) {
    setState(() => _query = query.trim());
    ref.read(searchViewModelProvider.notifier).search(query);
  }

  void _clear() {
    _controller.clear();
    setState(() => _query = '');
    ref.read(searchViewModelProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final results = ref.watch(searchViewModelProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: _submit,
                decoration: InputDecoration(
                  hintText: l.searchHint,
                  prefixIcon:
                      Icon(Icons.search, color: scheme.onSurfaceVariant),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close,
                              color: scheme.onSurfaceVariant),
                          onPressed: _clear,
                        ),
                ),
              ),
            ),
            if (_query.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.searchResultsFor(_query),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(Icons.tune, size: 18, color: palette.accentText),
                    const SizedBox(width: 6),
                    Text(
                      l.filter,
                      style: TextStyle(fontSize: 13, color: palette.accentText),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _query.isEmpty
                  ? EmptyView(
                      message: l.searchPrompt,
                      asset: AppAnim.searchEmpty,
                    )
                  : results.when(
                      loading: () => const LoadingView(),
                      error: (e, _) => ErrorView(message: '$e'),
                      data: (articles) {
                        if (articles.isEmpty) {
                          return EmptyView(
                            message: l.searchEmpty,
                            asset: AppAnim.searchEmpty,
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: articles.length,
                          itemBuilder: (_, i) =>
                              SearchResultCard(article: articles[i]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchResultCard extends StatelessWidget {
  const SearchResultCard({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final snippet = Formatters.plainSnippet(article.body);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: NeonCard(
        padding: const EdgeInsets.all(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(article: article),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PostImage(article: article, size: 88),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TopicBadge(topic: article.topic),
                      const Spacer(),
                      Icon(Icons.schedule,
                          size: 13, color: palette.textDim),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.timeAgo(article.publishedAt,
                            nowLabel: l.timeNow),
                        style: TextStyle(fontSize: 12, color: palette.textDim),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                  if (snippet.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: palette.textDim),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.readingTime(Formatters.readingMinutes(snippet)),
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.accentText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopicBadge extends StatelessWidget {
  const TopicBadge({super.key, required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '#$topic',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: palette.accentText,
        ),
      ),
    );
  }
}
