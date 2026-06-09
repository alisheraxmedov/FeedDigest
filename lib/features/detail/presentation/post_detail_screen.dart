import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../feed/data/models/reddit_post.dart';
import '../../feed/presentation/widgets/post_image.dart';
import '../../feed/presentation/widgets/subscribe_button.dart';
import '../../feed/presentation/widgets/vote_buttons.dart';
import '../../summary/application/summary_providers.dart';
import '../../summary/presentation/summary_sheet.dart';
import 'widgets/comment_tile.dart';

/// Full post view: complete body + image, engagement stats, an AI summary
/// action, and the top comments.
class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key, required this.post});

  final RedditPost post;

  static Route<void> route(RedditPost post) {
    return MaterialPageRoute(builder: (_) => PostDetailScreen(post: post));
  }

  Future<void> _openInBrowser(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(post.fullPermalink),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Havolani ochib bo‘lmadi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('r/${post.subreddit}'),
        actions: [
          IconButton(
            tooltip: 'Reddit‘da ochish',
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: () => _openInBrowser(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'r/${post.subreddit}',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              SubscribeButton(subreddit: post.subreddit),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'u/${post.author} · ${post.timeAgo}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            post.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, height: 1.25),
          ),
          if (post.hasImage) ...[
            const SizedBox(height: 14),
            PostImage(url: post.imageUrl),
          ],
          if (post.selftext.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              post.selftext.trim(),
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ],
          const SizedBox(height: 16),
          _StatsBar(post: post),
          const SizedBox(height: 16),
          _AiSummaryButton(onTap: () => showSummarySheet(context, post)),
          const SizedBox(height: 24),
          Text(
            'Izohlar',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          _CommentsSection(post: post),
        ],
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.post});

  final RedditPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        VoteButtons(post: post, compact: false),
        const SizedBox(width: 16),
        Icon(Icons.mode_comment_outlined,
            size: 20, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          post.compactComments,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CommentsSection extends ConsumerWidget {
  const _CommentsSection({required this.post});

  final RedditPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(commentsProvider(post));
    final theme = Theme.of(context);

    return comments.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              _messageFor(error),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => ref.invalidate(commentsProvider(post)),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Qayta urinish'),
            ),
          ],
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Hozircha izohlar yo‘q.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          );
        }
        return Column(
          children: [for (final c in items) CommentTile(comment: c)],
        );
      },
    );
  }

  String _messageFor(Object error) {
    final msg = error.toString();
    final idx = msg.indexOf(': ');
    return idx >= 0 ? msg.substring(idx + 2) : msg;
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
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'AI Xulosa · o‘zbekcha',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
