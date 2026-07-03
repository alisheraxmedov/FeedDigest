/*
ArticleDetailScreen is the in-app reading page opened when a card is tapped. It
shows a hero image (dev.to cover) or a favicon banner (Hacker News), the source
and topic, the title, author and engagement metadata, the article body, and two
actions: open the original article and request an AI summary.
*/
import 'dart:ui' show ImageFilter;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/prefs/preferences.dart';
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
import '../viewmodel/read_state_viewmodel.dart';
import '../viewmodel/streak_viewmodel.dart';
import 'widgets/reader_settings_sheet.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  const ArticleDetailScreen({super.key, required this.article});

  final Article article;

  @override
  ConsumerState<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Mark the article read once the first frame is up (avoids mutating a
    // provider mid-build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final now = DateTime.now();
      ref
          .read(readStateProvider.notifier)
          .markRead(widget.article.id, nowMs: now.millisecondsSinceEpoch);
      // DST-stable local calendar day index for the streak (see streak_viewmodel).
      ref.read(streakProvider.notifier).recordActivity(localDayIndex(now));
    });
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
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
    // Compose the reader's text scale with the system scale rather than
    // replacing it (accessibility-friendly).
    final systemScale = MediaQuery.textScalerOf(context).scale(1);
    final readerScaler = TextScaler.linear(
      ref.watch(readerTextScaleProvider) * systemScale,
    );
    ref.listen(articleTranslationProvider(article), (prev, next) {
      if (next.error && (prev == null || !prev.error)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.summaryFailed)));
      }
    });
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 60,
        leading: Center(
          child: _SquareIconButton(
            icon: Icons.arrow_back,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: Text(
          article.source,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: l.navSaved,
              icon: Icon(
                isFav ? Icons.bookmark : Icons.bookmark_border,
                color: isFav ? palette.accent : scheme.onSurface,
              ),
              onPressed: () =>
                  ref.read(favoritesViewModelProvider.notifier).toggle(article),
            ),
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
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: readerScaler),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopicLine(article: article),
                  const SizedBox(height: 12),
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 23,
                      height: 1.24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AuthorRow(article: article),
                  const SizedBox(height: 16),
                  _ReaderToolbar(
                    onText: () => showReaderSettingsSheet(context),
                    translateActive: translation.showing,
                    translateBusy: translation.loading,
                    onTranslate: translation.loading
                        ? null
                        : () => ref
                              .read(
                                articleTranslationProvider(article).notifier,
                              )
                              .toggle(),
                    onAskAi: () => showArticleChatSheet(context, article),
                  ),
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.navBar,
            border: Border(top: BorderSide(color: palette.mutedBorder)),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  flex: 8,
                  child: NeonButton(
                    label: l.aiSummary,
                    icon: Icons.auto_awesome,
                    onPressed: () => showSummarySheet(context, article),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _openLink(article.link),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(
                        l.articleShort,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.onSurface,
                        side: BorderSide(color: palette.mutedBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A 38px rounded-12 bordered icon button — the decluttered AppBar's back tile.
class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final button = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.mutedBorder),
          ),
          child: Icon(icon, size: 20, color: scheme.onSurface),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Inline reader toolbar under the meta row: three equal pills that reuse the
/// former AppBar actions (text size, translate, ask-AI) in their new placement.
class _ReaderToolbar extends StatelessWidget {
  const _ReaderToolbar({
    required this.onText,
    required this.onTranslate,
    required this.translateActive,
    required this.translateBusy,
    required this.onAskAi,
  });

  final VoidCallback onText;
  final VoidCallback? onTranslate;
  final bool translateActive;
  final bool translateBusy;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _ToolPill(
            icon: Icons.text_fields,
            label: l.readerText,
            onTap: onText,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToolPill(
            icon: Icons.translate,
            label: l.translateTooltip,
            onTap: onTranslate,
            active: translateActive,
            busy: translateBusy,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToolPill(
            icon: Icons.forum_outlined,
            label: l.chatTooltip,
            onTap: onAskAi,
            accent: true,
          ),
        ),
      ],
    );
  }
}

class _ToolPill extends StatelessWidget {
  const _ToolPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
    this.active = false,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool accent;
  final bool active;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final highlighted = accent || active;
    final fg = highlighted ? palette.accentText : scheme.onSurfaceVariant;
    return Material(
      color: highlighted ? palette.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlighted ? palette.accent : palette.mutedBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              busy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.accent,
                      ),
                    )
                  : Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
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
        borderRadius: BorderRadius.circular(18),
        child: article.hasImage
            ? Container(
                width: double.infinity,
                height: 172,
                alignment: Alignment.center,
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl,
                  width: double.infinity,
                  height: 172,
                  fit: BoxFit.contain,
                  memCacheHeight: (172 * MediaQuery.devicePixelRatioOf(context))
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
      height: 150,
      decoration: BoxDecoration(
        color: palette.iconCircle,
        border: Border.all(color: palette.mutedBorder),
        borderRadius: BorderRadius.circular(18),
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
