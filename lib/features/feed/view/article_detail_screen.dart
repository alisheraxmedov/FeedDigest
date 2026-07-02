/*
ArticleDetailScreen is the in-app reading page opened when a card is tapped. It
shows a hero image (dev.to cover) or a favicon banner (Hacker News), the source
and topic, the title, author and engagement metadata, the article body, and two
actions: open the original article and request an AI summary.
*/
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/article.dart';
import '../../chat/view/article_chat_sheet.dart';
import '../../favorites/viewmodel/favorites_viewmodel.dart';
import '../../summary/view/summary_sheet.dart';
import '../viewmodel/article_body_viewmodel.dart';
import '../viewmodel/article_translation_viewmodel.dart';

class ArticleDetailScreen extends ConsumerWidget {
  const ArticleDetailScreen({super.key, required this.article});

  final Article article;

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
    final bodyAsync = ref.watch(articleBodyProvider(article));
    final translation = ref.watch(articleTranslationProvider(article));
    ref.listen(articleTranslationProvider(article), (prev, next) {
      if (next.error && (prev == null || !prev.error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.summaryFailed)),
        );
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(article.source),
        actions: [
          IconButton(
            tooltip: l.translateTooltip,
            icon: translation.loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.accent,
                    ),
                  )
                : Icon(
                    Icons.translate,
                    color: translation.showing
                        ? palette.accent
                        : scheme.onSurface,
                  ),
            onPressed: translation.loading
                ? null
                : () => ref
                      .read(articleTranslationProvider(article).notifier)
                      .toggle(),
          ),
          IconButton(
            tooltip: l.chatTooltip,
            icon: Icon(Icons.forum_outlined, color: scheme.onSurface),
            onPressed: () => showArticleChatSheet(context, article),
          ),
          IconButton(
            tooltip: l.navSaved,
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? palette.accent : scheme.onSurface,
            ),
            onPressed: () =>
                ref.read(favoritesViewModelProvider.notifier).toggle(article),
          ),
        ],
      ),
      bottomNavigationBar: _BottomActions(article: article),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 21,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _AuthorRow(article: article),
                if (translation.showing && translation.text != null)
                  _BodyContent(
                    article: article,
                    content: translation.text!,
                    forceMarkdown: true,
                  )
                else
                  bodyAsync.when(
                    loading: () => _BodyContent(
                      article: article,
                      content: article.body,
                      loading: true,
                    ),
                    error: (_, _) =>
                        _BodyContent(article: article, content: article.body),
                    data: (full) => _BodyContent(
                      article: article,
                      content: full,
                      loading: translation.loading,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed bottom action bar, pinned like a navbar so the two actions stay
/// reachable without scrolling to the end of the article.
class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: palette.mutedBorder)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: NeonButton(
                label: l.articleShort,
                uppercase: true,
                icon: Icons.open_in_new,
                onPressed: () => launchUrl(
                  Uri.parse(article.link),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NeonGhostButton(
                label: l.aiShort,
                uppercase: true,
                icon: Icons.auto_awesome,
                onPressed: () => showSummarySheet(context, article),
              ),
            ),
          ],
        ),
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
            ? Container(
                width: double.infinity,
                height: 200,
                alignment: Alignment.center,
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.contain,
                  memCacheHeight: (200 * MediaQuery.devicePixelRatioOf(context))
                      .round(),
                  errorWidget: (_, _, _) => _faviconBanner(palette),
                ),
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
              errorWidget: (_, _, _) => Icon(
                Icons.article_outlined,
                size: 48,
                color: palette.accentText,
              ),
            ),
    );
  }
}

/// Renders the article body with the viewer that matches the source's data:
/// dev.to returns markdown (`body_markdown`) → Markdown viewer; Hacker News
/// returns HTML (`story_text`) → HTML viewer.
class _BodyContent extends StatelessWidget {
  const _BodyContent({
    required this.article,
    required this.content,
    this.loading = false,
    this.forceMarkdown = false,
  });

  final Article article;
  final String content;
  final bool loading;

  /// Translated bodies come back as Markdown regardless of the source format,
  /// so the detail screen forces the Markdown viewer for them.
  final bool forceMarkdown;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final trimmed = content.trim();
    if (trimmed.isEmpty && !loading) return const SizedBox(height: 8);
    final isMarkdown = forceMarkdown || article.id.startsWith('devto-');
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (trimmed.isNotEmpty)
            isMarkdown
                ? _MarkdownView(data: trimmed)
                : _HtmlView(data: trimmed),
          if (loading) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: palette.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

void _openLink(String? url) {
  if (url == null || url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri != null) {
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _MarkdownView extends StatelessWidget {
  const _MarkdownView({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);
    // Strip dev.to Liquid embeds ({% embed ... %}) that no renderer handles.
    final clean = data.replaceAll(RegExp(r'\{%[^%]*%\}'), '').trim();
    final body = TextStyle(
      fontSize: 17,
      height: 1.55,
      color: scheme.onSurface.withValues(alpha: 0.9),
    );
    return MarkdownBody(
      data: clean,
      selectable: true,
      onTapLink: (_, href, _) => _openLink(href),
      styleSheet: MarkdownStyleSheet(
        p: body,
        a: TextStyle(
          color: palette.accentText,
          decoration: TextDecoration.underline,
        ),
        h1: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        h2: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        h3: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14.5,
          color: scheme.onSurface,
          backgroundColor: palette.iconCircle,
        ),
        codeblockPadding: const EdgeInsets.all(14),
        codeblockDecoration: BoxDecoration(
          color: palette.iconCircle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.mutedBorder),
        ),
        blockquotePadding: const EdgeInsets.symmetric(horizontal: 14),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: palette.accent, width: 3)),
        ),
      ),
    );
  }
}

class _HtmlView extends StatelessWidget {
  const _HtmlView({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);
    return Html(
      data: data,
      onLinkTap: (url, _, _) => _openLink(url),
      style: {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(17),
          lineHeight: LineHeight.number(1.55),
          color: scheme.onSurface.withValues(alpha: 0.9),
        ),
        'a': Style(color: palette.accentText),
        'pre': Style(
          backgroundColor: palette.iconCircle,
          padding: HtmlPaddings.all(12),
        ),
      },
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
        Flexible(
          child: Text(
            article.source,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: palette.mutedBorder,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '#${article.topic}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: palette.accentText),
          ),
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
          decoration: BoxDecoration(
            color: palette.iconCircle,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person, size: 20, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
        Icon(
          Icons.chat_bubble_outline,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          Formatters.compactScore(article.commentCount),
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
