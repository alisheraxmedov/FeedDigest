import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/reddit_post.dart';
import '../viewmodel/summary_viewmodel.dart';

Future<void> showSummarySheet(BuildContext context, RedditPost post) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SummarySheet(post: post),
  );
}

class SummarySheet extends ConsumerWidget {
  const SummarySheet({super.key, required this.post});

  final RedditPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(summaryViewModelProvider(post));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(post.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          summary.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: LoadingView(),
            ),
            error: (e, _) => ErrorView(
              message: '$e',
              onRetry: () => ref.invalidate(summaryViewModelProvider(post)),
            ),
            data: (text) => Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
