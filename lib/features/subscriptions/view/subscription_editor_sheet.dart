/*
SubscriptionEditorSheet manages the topics that feed the home list. It is opened
from the "+" chip on the feed chip row: the user types a topic, adds it, and can
remove existing topics. Topics are persisted by SubscriptionsViewModel.
*/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../viewmodel/subscriptions_viewmodel.dart';

Future<void> showSubscriptionEditor(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
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
  final _topic = TextEditingController();

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  void _add() {
    final topic = _topic.text.trim();
    if (topic.isEmpty) return;
    ref.read(subscriptionsViewModelProvider.notifier).subscribe(topic);
    _topic.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final subs = ref.watch(subscriptionsViewModelProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.topicsTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _topic,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: l.topicLabel,
                      prefixText: '#',
                      prefixStyle: TextStyle(color: palette.accentText),
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _add,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.onAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      l.add,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final sub in subs)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.tag, color: palette.accentText),
                      title: Text(sub.label),
                      subtitle: Text(
                        sub.displayName,
                        style: TextStyle(color: palette.textDim),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: scheme.error),
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
      ),
    );
  }
}
