import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/topic_chip_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../subscriptions/view/subscription_editor_sheet.dart';
import '../../../subscriptions/viewmodel/subscriptions_viewmodel.dart';
import '../../viewmodel/feed_viewmodel.dart';

class SubscriptionBar extends ConsumerWidget {
  const SubscriptionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final subs = ref.watch(subscriptionsViewModelProvider);
    final selected = ref.watch(selectedTopicProvider);
    if (subs.isEmpty) return const SizedBox.shrink();
    return TopicChipBar(
      allLabel: l.chipAll,
      selected: selected,
      items: [
        for (final sub in subs)
          TopicChipItem(label: sub.label, value: sub.topic),
      ],
      onSelected: (value) =>
          ref.read(selectedTopicProvider.notifier).select(value),
      trailing: _AddTopicButton(
        tooltip: l.topicsTitle,
        onTap: () => showSubscriptionEditor(context),
      ),
    );
  }
}

class _AddTopicButton extends StatelessWidget {
  const _AddTopicButton({required this.onTap, required this.tooltip});

  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: palette.mutedBorder),
          ),
          child: Icon(Icons.add, size: 18, color: palette.textDim),
        ),
      ),
    );
  }
}
