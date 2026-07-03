/*
Full-height chat sheet for asking Gemini about the current article. User turns
render as accent bubbles on the right, model replies as surface bubbles on the
left. The composer stays above the keyboard; the list auto-scrolls on new turns.
*/
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/article.dart';
import '../../../models/chat_message.dart';
import '../../settings/view/settings_screen.dart';
import '../viewmodel/article_chat_viewmodel.dart';

Future<void> showArticleChatSheet(BuildContext context, Article article) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ArticleChatSheet(article: article),
  );
}

class ArticleChatSheet extends ConsumerStatefulWidget {
  const ArticleChatSheet({super.key, required this.article});

  final Article article;

  @override
  ConsumerState<ArticleChatSheet> createState() => _ArticleChatSheetState();
}

class _ArticleChatSheetState extends ConsumerState<ArticleChatSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    // Ignore submits while a send is in flight — otherwise the field clears and
    // the view model's `sending` guard silently drops the typed question.
    if (ref.read(articleChatProvider(widget.article)).sending) return;
    _input.clear();
    ref.read(articleChatProvider(widget.article).notifier).send(text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(articleChatProvider(widget.article));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.82,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _handle(palette),
            _header(context, l, palette, scheme),
            Divider(height: 1, color: palette.mutedBorder),
            Expanded(
              child: state.messages.isEmpty
                  ? _empty(l, palette)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.messages.length,
                      itemBuilder: (_, i) =>
                          _Bubble(message: state.messages[i]),
                    ),
            ),
            if (state.sending) _typing(l, palette),
            if (state.errorCode != null)
              _errorRow(context, l, palette, state.errorCode!),
            _composer(l, palette, scheme, state.sending),
          ],
        ),
      ),
    );
  }

  Widget _handle(AppPalette palette) => Container(
    width: 36,
    height: 4,
    margin: const EdgeInsets.only(top: 10, bottom: 8),
    decoration: BoxDecoration(
      color: palette.mutedBorder,
      borderRadius: BorderRadius.circular(999),
    ),
  );

  Widget _header(
    BuildContext context,
    AppLocalizations l,
    AppPalette palette,
    ColorScheme scheme,
  ) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 8, 10),
    child: Row(
      children: [
        Icon(Icons.forum_outlined, size: 20, color: palette.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            l.chatTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );

  Widget _empty(AppLocalizations l, AppPalette palette) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 40,
            color: palette.accent.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            l.chatEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: palette.textDim),
          ),
        ],
      ),
    ),
  );

  Widget _typing(AppLocalizations l, AppPalette palette) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: palette.accent,
            ),
          ),
          const SizedBox(width: 10),
          Text('…', style: TextStyle(fontSize: 14, color: palette.textDim)),
        ],
      ),
    ),
  );

  Widget _errorRow(
    BuildContext context,
    AppLocalizations l,
    AppPalette palette,
    String code,
  ) {
    final noKey = code == 'no_key';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              noKey ? l.summaryNoKey : l.summaryFailed,
              style: TextStyle(fontSize: 13, color: palette.textDim),
            ),
          ),
          if (noKey)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: Text(l.summaryAddKey),
            ),
        ],
      ),
    );
  }

  Widget _composer(
    AppLocalizations l,
    AppPalette palette,
    ColorScheme scheme,
    bool sending,
  ) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: l.chatHint,
                filled: true,
                fillColor: palette.iconCircle,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: sending ? palette.mutedBorder : palette.accent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: sending ? null : _send,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.arrow_upward,
                  color: palette.onAccent,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? palette.accentSoft : palette.iconCircle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUser
                ? palette.accent.withValues(alpha: 0.3)
                : palette.mutedBorder,
          ),
        ),
        child: isUser
            ? Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: scheme.onSurface,
                ),
              )
            : MarkdownBody(
                data: message.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: scheme.onSurface,
                  ),
                  strong: const TextStyle(fontWeight: FontWeight.w700),
                  code: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13.5,
                    backgroundColor: scheme.surface,
                  ),
                ),
              ),
      ),
    );
  }
}
