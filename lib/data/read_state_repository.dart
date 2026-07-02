import 'package:hive_ce/hive.dart';

/// Tracks which articles the reader has opened, so the feed can dim them. Keyed
/// by the article's namespaced id → the epoch-ms it was first opened. Purely
/// local; no article content is stored here.
class ReadStateRepository {
  ReadStateRepository(this._box);

  final Box<dynamic> _box;

  bool isRead(String id) => _box.containsKey(id);

  Set<String> allRead() => _box.keys.cast<String>().toSet();

  Future<void> markRead(String id, int nowMs) => _box.put(id, nowMs);
}
