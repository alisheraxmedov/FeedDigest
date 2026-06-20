import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/state_views.dart';
import '../../subscriptions/viewmodel/subscriptions_viewmodel.dart';
import '../viewmodel/feed_viewmodel.dart';
import 'widgets/post_card.dart';
import 'widgets/post_skeleton.dart';
import 'widgets/subscription_bar.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = ref.watch(subscriptionsViewModelProvider);
    final feed = ref.watch(feedViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: Column(
        children: [
          const SubscriptionBar(),
          Expanded(
            child: subs.isEmpty
                ? const EmptyView(
                    message:
                        "Obuna yo'q. Qidiruv orqali hamjamiyatga obuna bo'ling.",
                  )
                : feed.when(
                    loading: () => const PostSkeleton(),
                    error: (e, _) => ErrorView(
                      message: '$e',
                      onRetry: () =>
                          ref.read(feedViewModelProvider.notifier).refresh(),
                    ),
                    data: (posts) {
                      if (posts.isEmpty) {
                        return const EmptyView(message: 'Hech narsa topilmadi');
                      }
                      return RefreshIndicator(
                        onRefresh: () =>
                            ref.read(feedViewModelProvider.notifier).refresh(),
                        child: ListView.builder(
                          itemCount: posts.length,
                          itemBuilder: (_, i) => PostCard(post: posts[i]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
