import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/subscriptions_viewmodel.dart';

Future<void> showSubscriptionEditor(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const SubscriptionEditorSheet(),
  );
}

class SubscriptionEditorSheet extends ConsumerStatefulWidget {
  const SubscriptionEditorSheet({super.key});

  @override
  ConsumerState<SubscriptionEditorSheet> createState() =>
      _SubscriptionEditorSheetState();
}

class _SubscriptionEditorSheetState
    extends ConsumerState<SubscriptionEditorSheet> {
  final _subreddit = TextEditingController();

  @override
  void dispose() {
    _subreddit.dispose();
    super.dispose();
  }

  void _add() {
    final sub = _subreddit.text.trim();
    if (sub.isEmpty) return;
    ref.read(subscriptionsViewModelProvider.notifier).subscribe(sub);
    _subreddit.clear();
  }

  @override
  Widget build(BuildContext context) {
    final subs = ref.watch(subscriptionsViewModelProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Obunalar', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _subreddit,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Subreddit',
              prefixText: 'r/',
            ),
            onSubmitted: (_) => _add(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: _add, child: const Text("Qo'shish")),
          ),
          const Divider(),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final sub in subs)
                  ListTile(
                    title: Text(sub.label),
                    subtitle: Text(sub.displayName),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref
                          .read(subscriptionsViewModelProvider.notifier)
                          .unsubscribe(sub.id),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
