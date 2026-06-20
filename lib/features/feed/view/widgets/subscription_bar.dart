import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodel/feed_viewmodel.dart';
import '../../../subscriptions/viewmodel/subscriptions_viewmodel.dart';

class SubscriptionBar extends ConsumerWidget {
  const SubscriptionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = ref.watch(subscriptionsViewModelProvider);
    final selected = ref.watch(selectedSubredditProvider);
    if (subs.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Hammasi'),
              selected: selected == null,
              onSelected: (_) =>
                  ref.read(selectedSubredditProvider.notifier).select(null),
            ),
          ),
          for (final sub in subs)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(sub.label),
                selected: selected == sub.subreddit,
                onSelected: (_) => ref
                    .read(selectedSubredditProvider.notifier)
                    .select(sub.subreddit),
              ),
            ),
        ],
      ),
    );
  }
}
