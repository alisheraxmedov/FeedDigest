import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/application/auth_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../application/feed_providers.dart';
import '../application/feed_state.dart';
import '../application/subscriptions_providers.dart';
import 'widgets/feed_list.dart';
import 'widgets/subscribe_button.dart';

/// A single tab: a label and the feed widget shown for it.
class _TabSpec {
  const _TabSpec({required this.label, required this.body});
  final String label;
  final Widget body;
}

/// Home screen. Logged in → [Bosh sahifa] + the user's subscribed subreddits.
/// Logged out → the manually configured topics.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // While the stored session is being restored on cold start, show a loader
    // instead of briefly flashing the logged-out tabs (and firing throwaway
    // fetches) before switching to the home feed.
    final authLoading =
        ref.watch(authControllerProvider.select((s) => s.isLoading));
    if (authLoading) {
      return Scaffold(
        appBar: AppBar(title: const _BrandTitle()),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final loggedIn = ref.watch(isLoggedInProvider);
    final sort = ref.watch(feedSortProvider);

    final tabs = loggedIn
        ? _loggedInTabs(ref, sort)
        : _loggedOutTabs(ref, sort);

    if (tabs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const _BrandTitle()),
        body: const AppEmptyView(
          icon: Icons.topic_outlined,
          title: 'Mavzular yo‘q',
          message: 'Sozlamalardan kamida bitta mavzu qo‘shing.',
        ),
      );
    }

    return DefaultTabController(
      key: ValueKey('$loggedIn-${tabs.length}'),
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const _BrandTitle(),
          actions: [
            _SortButton(
              current: sort,
              onSelected: (value) =>
                  ref.read(feedSortProvider.notifier).set(value),
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                tabs: [for (final t in tabs) Tab(text: t.label)],
              ),
            ),
          ),
        ),
        body: TabBarView(children: [for (final t in tabs) t.body]),
      ),
    );
  }

  List<_TabSpec> _loggedInTabs(WidgetRef ref, FeedSort sort) {
    final subs = ref.watch(subscriptionsProvider).value ?? const [];
    return [
      const _TabSpec(label: 'Bosh sahifa', body: HomeFeedList()),
      for (final s in subs)
        _TabSpec(
          label: s.name,
          body: _SubredditFeed(subreddit: s.name, sort: sort),
        ),
    ];
  }

  List<_TabSpec> _loggedOutTabs(WidgetRef ref, FeedSort sort) {
    final topics = ref.watch(topicsProvider);
    return [
      for (final t in topics)
        _TabSpec(
          label: t.label,
          body: _SubredditFeed(subreddit: t.subreddit, sort: sort),
        ),
    ];
  }
}

/// A subreddit feed with a header bar exposing the subscribe toggle.
class _SubredditFeed extends StatelessWidget {
  const _SubredditFeed({required this.subreddit, required this.sort});

  final String subreddit;
  final FeedSort sort;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'r/$subreddit',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              SubscribeButton(subreddit: subreddit),
            ],
          ),
        ),
        Expanded(
          child: FeedList(query: FeedQuery(subreddit: subreddit, sort: sort)),
        ),
      ],
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.bolt_rounded,
              size: 18, color: theme.colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 8),
        Text(AppConfig.appName,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.current, required this.onSelected});

  final FeedSort current;
  final ValueChanged<FeedSort> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<FeedSort>(
      tooltip: 'Saralash',
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final s in FeedSort.values)
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Text(s.label),
                if (s == current) ...[
                  const Spacer(),
                  Icon(Icons.check_rounded,
                      size: 18, color: Theme.of(context).colorScheme.primary),
                ],
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(current.label,
                style: Theme.of(context).textTheme.labelLarge),
            const Icon(Icons.arrow_drop_down_rounded),
          ],
        ),
      ),
    );
  }
}
