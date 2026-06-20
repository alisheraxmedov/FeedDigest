import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/subreddit.dart';
import '../../subscriptions/viewmodel/subscriptions_viewmodel.dart';

class SubredditTile extends ConsumerWidget {
  const SubredditTile({super.key, required this.subreddit});

  final Subreddit subreddit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(subscriptionsViewModelProvider);
    final notifier = ref.read(subscriptionsViewModelProvider.notifier);
    final subscribed = notifier.isSubscribed(subreddit.name);
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: subreddit.hasIcon
            ? CachedNetworkImageProvider(subreddit.icon)
            : null,
        child: subreddit.hasIcon
            ? null
            : Text(subreddit.name.isEmpty
                ? '?'
                : subreddit.name[0].toUpperCase()),
      ),
      title: Text(subreddit.namePrefixed),
      subtitle: Text("${Formatters.compactScore(subreddit.subscribers)} a'zo"),
      trailing: subscribed
          ? OutlinedButton(
              onPressed: () =>
                  notifier.toggle(subreddit.name, label: subreddit.name),
              child: const Text('Obuna ✓'),
            )
          : FilledButton(
              onPressed: () =>
                  notifier.toggle(subreddit.name, label: subreddit.name),
              child: const Text('Obuna'),
            ),
    );
  }
}
