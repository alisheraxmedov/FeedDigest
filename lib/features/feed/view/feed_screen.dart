import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sources/article_source.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../subscriptions/viewmodel/subscriptions_viewmodel.dart';
import '../viewmodel/feed_source_viewmodel.dart';
import '../viewmodel/feed_viewmodel.dart';
import 'widgets/post_card.dart';
import 'widgets/post_skeleton.dart';
import 'widgets/subscription_bar.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  void _openSortPicker(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    showOptionPicker<FeedSort>(
      context: context,
      title: l.filter,
      selected: ref.read(feedSortProvider),
      options: [
        PickerOption(
            value: FeedSort.newest, label: l.sortNewest, icon: Icons.schedule),
        PickerOption(
            value: FeedSort.popular,
            label: l.sortPopular,
            icon: Icons.local_fire_department),
      ],
      onSelected: (sort) => ref.read(feedSortProvider.notifier).select(sort),
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
    final sortLabel = sort == FeedSort.newest ? l.sortNewest : l.sortPopular;
    return Scaffold(
      appBar: AppBar(
        leading: Center(child: Icon(Icons.hub, color: palette.accent)),
        title: Text(l.appTitle),
      ),
      body: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _openSortPicker(context, ref),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, color: palette.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    sortLabel,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const SubscriptionBar(),
          const SizedBox(height: 4),
          Expanded(
            child: subs.isEmpty
                ? EmptyView(message: l.feedNoSubscriptions)
                : feed.when(
                    loading: () => const PostSkeleton(),
                    error: (e, _) => ErrorView(
                      message: '$e',
                      onRetry: () =>
                          ref.read(feedViewModelProvider.notifier).refresh(),
                    ),
                    data: (articles) {
                      if (articles.isEmpty) {
                        return EmptyView(message: l.feedEmpty);
                      }
                      return RefreshIndicator(
                        onRefresh: () =>
                            ref.read(feedViewModelProvider.notifier).refresh(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 96),
                          itemCount: articles.length,
                          itemBuilder: (_, i) => PostCard(article: articles[i]),
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
