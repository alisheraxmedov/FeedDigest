import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../shell/view/widgets/home_drawer.dart';
import '../../subscriptions/viewmodel/subscriptions_viewmodel.dart';
import '../../voice_search/view/voice_search_fab.dart';
import '../viewmodel/feed_viewmodel.dart';
import '../viewmodel/streak_viewmodel.dart';
import 'widgets/feed_pager.dart';
import 'widgets/post_card.dart';
import 'widgets/post_skeleton.dart';
import 'widgets/subscription_bar.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final subs = ref.watch(subscriptionsViewModelProvider);
    final feed = ref.watch(feedViewModelProvider);
    final page = ref.watch(feedPageProvider);
    final streak = ref.watch(streakProvider);
    final navClear = 64 + MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      drawer: const HomeDrawer(),
      floatingActionButton: const VoiceSearchFab(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 16,
        // Brand logo + wordmark replace the hamburger. Tapping it still opens
        // the drawer, so every destination stays reachable (no nav change).
        title: Builder(
          builder: (barContext) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: Scaffold.of(barContext).openDrawer,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.asset(
                    'assets/icons/feeddigest-1b-monogram-f.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                const Wordmark(fontSize: 21),
              ],
            ),
          ),
        ),
        actions: [
          if (streak.current > 0)
            Center(
              child: Tooltip(
                message: l.streakDays(streak.current),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: palette.accentText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${streak.current}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: palette.accentText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(width: 12),
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
