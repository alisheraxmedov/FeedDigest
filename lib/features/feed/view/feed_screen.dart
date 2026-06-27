import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sources/article_source.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../subscriptions/viewmodel/subscriptions_viewmodel.dart';
import '../viewmodel/feed_source_viewmodel.dart';
import '../viewmodel/feed_viewmodel.dart';
import 'widgets/feed_pager.dart';
import 'widgets/post_card.dart';
import 'widgets/post_skeleton.dart';
import 'widgets/subscription_bar.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  PopupMenuItem<FeedSort> _sortItem(
    FeedSort value,
    String label,
    IconData icon,
    FeedSort current,
    AppPalette palette,
  ) {
    final active = value == current;
    return PopupMenuItem<FeedSort>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: active ? palette.accent : null),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (active) Icon(Icons.check, size: 18, color: palette.accent),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final subs = ref.watch(subscriptionsViewModelProvider);
    final feed = ref.watch(feedViewModelProvider);
    final sort = ref.watch(feedSortProvider);
    final page = ref.watch(feedPageProvider);
    final navClear = 64 + MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      appBar: AppBar(
        leading: Center(child: Icon(Icons.hub, color: palette.accent)),
        title: Text(l.appTitle),
        actions: [
          PopupMenuButton<FeedSort>(
            tooltip: l.filter,
            icon: Icon(Icons.more_vert, color: scheme.onSurface),
            onSelected: (value) =>
                ref.read(feedSortProvider.notifier).select(value),
            itemBuilder: (context) => [
              _sortItem(
                FeedSort.newest,
                l.sortNewest,
                Icons.schedule,
                sort,
                palette,
              ),
              _sortItem(
                FeedSort.popular,
                l.sortPopular,
                Icons.local_fire_department,
                sort,
                palette,
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const SubscriptionBar(),
          const SizedBox(height: 4),
          Expanded(
            child: subs.isEmpty
                ? EmptyView(message: l.feedNoSubscriptions)
                : feed.when(
                    skipLoadingOnReload: true,
                    loading: () => const PostSkeleton(),
                    error: (e, _) => ErrorView(
                      message: l.feedLoadError,
                      onRetry: () =>
                          ref.read(feedViewModelProvider.notifier).refresh(),
                    ),
                    data: (fp) {
                      if (fp.items.isEmpty) {
                        return EmptyView(message: l.feedEmpty);
                      }
                      final showPager = !(page == 1 && !fp.hasNext);
                      return RefreshIndicator(
                        onRefresh: () =>
                            ref.read(feedViewModelProvider.notifier).refresh(),
                        child: ListView.builder(
                          key: ValueKey('feed-page-$page'),
                          padding: EdgeInsets.only(
                            top: 4,
                            bottom: navClear + 16,
                          ),
                          itemCount: fp.items.length + (showPager ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i >= fp.items.length) return const FeedPager();
                            return PostCard(article: fp.items[i]);
                          },
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
