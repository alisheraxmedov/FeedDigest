import 'package:hive_ce/hive.dart';
import '../core/config/app_config.dart';
import '../models/subscription.dart';

class SubscriptionRepository {
  SubscriptionRepository(this._box, this._meta);

  final Box<dynamic> _box;
  final Box<dynamic> _meta;

  static const String _seededKey = 'seeded';

  List<Subscription> all() {
    final list = _box.values
        .map((v) => Subscription.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  bool isSubscribed(String id) => _box.containsKey(id.toLowerCase());

  Future<void> subscribe(String topic, {String? label}) {
    final sub = Subscription.create(topic, label: label);
    return _box.put(sub.id, sub.toJson());
  }

  Future<void> unsubscribe(String id) => _box.delete(id.toLowerCase());

  Future<void> toggle(String topic, {String? label}) {
    final id = topic.toLowerCase();
    return isSubscribed(id) ? unsubscribe(id) : subscribe(topic, label: label);
  }

  Future<void> seedDefaultsIfNeeded() async {
    if (_meta.get(_seededKey) == true) return;
    for (final entry in AppConfig.defaultTopics) {
      final sub = Subscription.create(entry.topic, label: entry.label);
      await _box.put(sub.id, sub.toJson());
    }
    await _meta.put(_seededKey, true);
  }
}
