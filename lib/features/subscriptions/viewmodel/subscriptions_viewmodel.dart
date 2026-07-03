import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../models/subscription.dart';

final subscriptionsViewModelProvider =
    NotifierProvider<SubscriptionsViewModel, List<Subscription>>(
      SubscriptionsViewModel.new,
    );

class SubscriptionsViewModel extends Notifier<List<Subscription>> {
  @override
  List<Subscription> build() => ref.watch(subscriptionRepositoryProvider).all();

  bool isSubscribed(String topic) =>
      ref.read(subscriptionRepositoryProvider).isSubscribed(topic);

  /// Re-reads the subscriptions from the repository. Used after a repository
  /// write done outside this notifier (e.g. the first-run interests picker
  /// seeds directly) to push the change to the UI without a provider
  /// invalidation — invalidating while the home feed is paused under a modal
  /// route corrupts Riverpod's paused-subscription bookkeeping.
  void refresh() => state = ref.read(subscriptionRepositoryProvider).all();

  Future<void> toggle(String topic, {String? label}) async {
    final repo = ref.read(subscriptionRepositoryProvider);
    await repo.toggle(topic, label: label);
    state = repo.all();
  }

  Future<void> subscribe(String topic, {String? label}) async {
    final repo = ref.read(subscriptionRepositoryProvider);
    await repo.subscribe(topic, label: label);
    state = repo.all();
  }

  Future<void> unsubscribe(String id) async {
    final repo = ref.read(subscriptionRepositoryProvider);
    await repo.unsubscribe(id);
    state = repo.all();
  }
}
