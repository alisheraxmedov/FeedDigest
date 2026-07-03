/*
Source picker helper. Source selection lives in Settings (not on the feed):
openSourcePicker shows the "Manbalar" bottom sheet listing the available
sources; the choice is persisted in Hive and the feed reloads from it.
*/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/sources/article_source.dart';
import '../../../../core/widgets/neon_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../viewmodel/feed_source_viewmodel.dart';

IconData sourceIcon(FeedSource source) => switch (source) {
  FeedSource.hackerNews => Icons.local_fire_department,
  FeedSource.devto => Icons.code,
  FeedSource.lobsters => Icons.forum_outlined,
  FeedSource.habr => Icons.article_outlined,
  FeedSource.vcru => Icons.business_center_outlined,
};

void openSourcePicker(BuildContext context, WidgetRef ref) {
  final l = AppLocalizations.of(context);
  final current = ref.read(feedSourceProvider);
  showOptionPicker<FeedSource>(
    context: context,
    title: l.sourcesTitle,
    selected: current,
    options: [
      for (final source in FeedSource.values)
        PickerOption(
          value: source,
          label: source.label,
          icon: sourceIcon(source),
        ),
    ],
    onSelected: (source) =>
        ref.read(feedSourceProvider.notifier).select(source),
  );
}
