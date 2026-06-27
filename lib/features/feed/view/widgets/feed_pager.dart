/*
A compact, elegant numbered pager rendered as the LAST item of the feed list,
after all the articles. A sliding window of page chips (current highlighted in
the accent) flanked by prev/next arrows. The total page count is unknown for the
dev.to source, so the window ends at the last reachable page (current, or
current+1 when the feed reports another page is available).
*/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../viewmodel/feed_viewmodel.dart';

class FeedPager extends ConsumerWidget {
  const FeedPager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(feedPageProvider);
    final feed = ref.watch(feedViewModelProvider);
    final value = feed.value;
    final hasNext = value?.hasNext ?? false;
    final hasItems = value?.items.isNotEmpty ?? false;
    final busy = feed.isLoading;

    // A single page with nothing after it needs no pager.
    if (!hasItems || (page == 1 && !hasNext)) return const SizedBox.shrink();

    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;

    // Up to four page numbers ending at the last reachable page.
    final end = hasNext ? page + 1 : page;
    final start = (end - 3) < 1 ? 1 : end - 3;
    final numbers = [for (var n = start; n <= end; n++) n];

    final controller = ref.read(feedPageProvider.notifier);

    Widget arrow(List<List<dynamic>> icon, bool enabled, VoidCallback onTap) {
      return _PagerCell(
        onTap: enabled && !busy ? onTap : null,
        child: HugeIcon(
          icon: icon,
          size: 18,
          color: enabled ? scheme.onSurface : palette.mutedBorder,
          strokeWidth: 1.9,
        ),
      );
    }

    Widget number(int n) {
      final selected = n == page;
      return _PagerCell(
        selected: selected,
        onTap: selected || busy ? null : () => controller.set(n),
        child: Text(
          '$n',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? palette.accentText : scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          arrow(HugeIcons.strokeRoundedArrowLeft01, page > 1, controller.prev),
          const SizedBox(width: 8),
          for (final n in numbers) ...[
            number(n),
            const SizedBox(width: 8),
          ],
          arrow(HugeIcons.strokeRoundedArrowRight01, hasNext, controller.next),
        ],
      ),
    );
  }
}

class _PagerCell extends StatelessWidget {
  const _PagerCell({required this.child, this.onTap, this.selected = false});

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: selected ? palette.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? palette.accent : palette.mutedBorder,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
