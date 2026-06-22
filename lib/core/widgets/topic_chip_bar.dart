/*
TopicChipBar — the horizontal, fixed-width topic filter bar shared by the Home
(feed) and Saved screens. It renders an "All" chip followed by one chip per
topic, with an optional trailing widget (e.g. the add-topic button on Home).
Keeping it in one place means both screens stay visually identical.
*/
import 'package:flutter/material.dart';
import 'neon_widgets.dart';

const double kTopicChipWidth = 104;
const double kTopicChipRadius = 10;

class TopicChipItem {
  const TopicChipItem({required this.label, required this.value});

  final String label;
  final String value;
}

class TopicChipBar extends StatelessWidget {
  const TopicChipBar({
    super.key,
    required this.allLabel,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.trailing,
  });

  final String allLabel;
  final List<TopicChipItem> items;

  /// Currently selected value; null means "All".
  final String? selected;

  /// Called with the chosen value, or null when "All" is tapped.
  final ValueChanged<String?> onSelected;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CategoryChip(
              label: allLabel,
              selected: selected == null,
              width: kTopicChipWidth,
              radius: kTopicChipRadius,
              onTap: () => onSelected(null),
            ),
          ),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CategoryChip(
                label: item.label,
                selected: selected == item.value,
                width: kTopicChipWidth,
                radius: kTopicChipRadius,
                onTap: () => onSelected(item.value),
              ),
            ),
          if (trailing != null) Center(child: trailing!),
        ],
      ),
    );
  }
}
