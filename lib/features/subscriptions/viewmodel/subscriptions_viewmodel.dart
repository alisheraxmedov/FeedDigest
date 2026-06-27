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
