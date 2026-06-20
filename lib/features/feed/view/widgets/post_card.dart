import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/reddit_post.dart';
import '../../../favorites/viewmodel/favorites_viewmodel.dart';
import '../../../subscriptions/viewmodel/subscriptions_viewmodel.dart';
import '../../../summary/view/summary_sheet.dart';
import 'post_image.dart';

class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post});

  final RedditPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(favoritesViewModelProvider);
    ref.watch(subscriptionsViewModelProvider);
    final isFav =
        ref.read(favoritesViewModelProvider.notifier).isFavorite(post.id);
    final isFollowing = ref
        .read(subscriptionsViewModelProvider.notifier)
        .isSubscribed(post.subreddit);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${post.subredditNamePrefixed} · u/${post.author} · ${Formatters.timeAgo(post.createdUtc)}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                PostImage(post: post),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.arrow_upward, size: 16),
                const SizedBox(width: 4),
                Text(Formatters.compactScore(post.score)),
                const SizedBox(width: 12),
                const Icon(Icons.mode_comment_outlined, size: 16),
                const SizedBox(width: 4),
                Text(Formatters.compactScore(post.numComments)),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(isFollowing ? Icons.person_remove : Icons.person_add,
                      size: 20),
                  tooltip: isFollowing ? 'Obunani bekor qilish' : 'Obuna',
                  onPressed: () => ref
                      .read(subscriptionsViewModelProvider.notifier)
                      .toggle(post.subreddit, label: post.subreddit),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                      size: 20),
                  onPressed: () => ref
                      .read(favoritesViewModelProvider.notifier)
                      .toggle(post),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  tooltip: 'Xulosa',
                  onPressed: () => showSummarySheet(context, post),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.open_in_new, size: 20),
                  onPressed: () => launchUrl(
                    Uri.parse(post.fullPermalink),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
