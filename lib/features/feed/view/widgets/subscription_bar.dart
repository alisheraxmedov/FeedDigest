import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/neon_widgets.dart';
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
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CategoryChip(
              label: l.chipAll,
              selected: selected == null,
              onTap: () =>
                  ref.read(selectedTopicProvider.notifier).select(null),
            ),
          ),
          for (final sub in subs)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CategoryChip(
                label: sub.label,
                selected: selected == sub.topic,
                onTap: () =>
                    ref.read(selectedTopicProvider.notifier).select(sub.topic),
              ),
            ),
          Center(child: _AddTopicButton(onTap: () => showSubscriptionEditor(context))),
        ],
      ),
    );
  }
}

class _AddTopicButton extends StatelessWidget {
  const _AddTopicButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return InkWell(
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
    );
  }
}
