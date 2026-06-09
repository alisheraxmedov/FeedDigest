import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../detail/presentation/post_detail_screen.dart';
import '../../../summary/presentation/summary_sheet.dart';
import '../../data/models/reddit_post.dart';
import 'post_image.dart';
import 'vote_buttons.dart';

/// Reddit-style post card: header, title, body preview, image, engagement
/// stats and the AI summary call-to-action.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});

  final RedditPost post;

  Future<void> _openInBrowser(BuildContext context) async {
    final uri = Uri.parse(post.fullPermalink);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Havolani ochib bo‘lmadi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(PostDetailScreen.route(post)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(post: post, onOpen: () => _openInBrowser(context)),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            if (post.selftext.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                post.selftext.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
            if (post.hasImage) ...[
              const SizedBox(height: 12),
              PostImage(url: post.imageUrl),
            ],
            const SizedBox(height: 14),
            _StatsRow(post: post, onOpen: () => _openInBrowser(context)),
            const SizedBox(height: 12),
            _AiSummaryButton(
              onTap: () => showSummarySheet(context, post),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.post, required this.onOpen});

  final RedditPost post;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final letter =
        post.subreddit.isNotEmpty ? post.subreddit[0].toUpperCase() : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: scheme.primaryContainer,
          child: Text(
            letter,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'r/${post.subreddit}',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'u/${post.author} · ${post.timeAgo}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (post.over18)
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '18+',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onOpen,
          icon: const Icon(Icons.open_in_new_rounded, size: 20),
          tooltip: 'Reddit‘da ochish',
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.post, required this.onOpen});

  final RedditPost post;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        VoteButtons(post: post),
        const SizedBox(width: 10),
        _Pill(
          icon: Icons.mode_comment_outlined,
          label: post.compactComments,
        ),
        const Spacer(),
        _Pill(
          icon: Icons.share_outlined,
          label: 'Ulashish',
          onTap: onOpen,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = scheme.onSurfaceVariant;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiSummaryButton extends StatelessWidget {
  const _AiSummaryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.aiGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 19, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'AI Xulosa · o‘zbekcha',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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
