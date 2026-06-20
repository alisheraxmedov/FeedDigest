import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../models/subscription.dart';

final subscriptionsViewModelProvider =
    NotifierProvider<SubscriptionsViewModel, List<Subscription>>(
        SubscriptionsViewModel.new);

class SubscriptionsViewModel extends Notifier<List<Subscription>> {
  @override
  List<Subscription> build() {
    final repo = ref.watch(subscriptionRepositoryProvider);
    repo.seedDefaultsIfNeeded();
    return repo.all();
  }

  bool isSubscribed(String subreddit) =>
      ref.read(subscriptionRepositoryProvider).isSubscribed(subreddit);

  Future<void> toggle(String subreddit, {String? label}) async {
    final repo = ref.read(subscriptionRepositoryProvider);
    await repo.toggle(subreddit, label: label);
    state = repo.all();
  }

  Future<void> subscribe(String subreddit, {String? label}) async {
    final repo = ref.read(subscriptionRepositoryProvider);
    await repo.subscribe(subreddit, label: label);
    state = repo.all();
  }

  Future<void> unsubscribe(String id) async {
    final repo = ref.read(subscriptionRepositoryProvider);
    await repo.unsubscribe(id);
    state = repo.all();
  }
}
