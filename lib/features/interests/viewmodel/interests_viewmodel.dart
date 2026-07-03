/*
InterestsSelectionController — holds the set of interest topics picked on the
first-run interests screen and commits them as Subscriptions. Selection is UI
state (a Set of topics); commit/skip are the only side-effecting actions.
*/
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/interests.dart';
import '../../../core/providers.dart';
import '../../subscriptions/viewmodel/subscriptions_viewmodel.dart';

final interestsSelectionProvider =
    NotifierProvider<InterestsSelectionController, Set<String>>(
      InterestsSelectionController.new,
    );

class InterestsSelectionController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  bool isSelected(String topic) => state.contains(topic);

  void toggle(String topic) {
    final next = Set<String>.from(state);
    if (!next.add(topic)) next.remove(topic);
    state = next;
  }

  /// Subscribes to every selected interest and marks the app seeded so the
  /// first-run picker doesn't show again, then refreshes the subscription list.
  Future<void> commit() async {
    final repo = ref.read(subscriptionRepositoryProvider);
    for (final group in InterestCatalog.groups) {
      for (final interest in group.interests) {
        if (state.contains(interest.topic)) {
          await repo.subscribe(interest.topic, label: interest.label);
        }
      }
    }
    await repo.markSeeded();
    ref.invalidate(subscriptionsViewModelProvider);
  }

  /// Skips the picker: seeds the default topics instead.
  Future<void> skipWithDefaults() async {
    await ref.read(subscriptionRepositoryProvider).seedDefaultsIfNeeded();
    ref.invalidate(subscriptionsViewModelProvider);
  }
}
