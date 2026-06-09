import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/vote_providers.dart';
import '../../data/models/reddit_post.dart';

/// Up / score / down vote control with optimistic state. Works from the feed
/// card and the detail screen. Prompts login when tapped while logged out.
class VoteButtons extends ConsumerWidget {
  const VoteButtons({super.key, required this.post, this.compact = true});

  final RedditPost post;
  final bool compact;

  Future<void> _vote(BuildContext context, WidgetRef ref, int dir) async {
    if (!ref.read(isLoggedInProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ovoz berish uchun Sozlamalardan Reddit hisobiga '
              'kiring.'),
        ),
      );
      return;
    }
    try {
      await ref.read(votesProvider.notifier).vote(post, dir);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_messageFor(error))));
      }
    }
  }

  String _messageFor(Object error) {
    final msg = error.toString();
    final idx = msg.indexOf(': ');
    return idx >= 0 ? msg.substring(idx + 2) : msg;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overrides = ref.watch(votesProvider);
    final view = voteViewFor(post, overrides);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final iconSize = compact ? 19.0 : 24.0;

    final scoreColor = view.isUp
        ? AppColors.upvote
        : view.isDown
            ? AppColors.downvote
            : muted;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(30),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ArrowButton(
            icon: Icons.arrow_upward_rounded,
            size: iconSize,
            color: view.isUp ? AppColors.upvote : muted,
            onTap: () => _vote(context, ref, 1),
          ),
          Text(
            Formatters.compactNumber(view.score),
            style: theme.textTheme.labelLarge?.copyWith(
              color: scoreColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          _ArrowButton(
            icon: Icons.arrow_downward_rounded,
            size: iconSize,
            color: view.isDown ? AppColors.downvote : muted,
            onTap: () => _vote(context, ref, -1),
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.size,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: size,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}
