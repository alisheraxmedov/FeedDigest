import 'package:hive_ce/hive.dart';

/// Caches resolved article bodies so a previously opened article reads offline.
/// Keyed by article id → body text, capped at [maxEntries] with FIFO eviction
/// (Hive preserves insertion order) so it can't grow without bound.
class ArticleBodyCacheRepository {
  ArticleBodyCacheRepository(this._box, {this.maxEntries = 200});

  final Box<dynamic> _box;
  final int maxEntries;

  String? get(String id) {
    final value = _box.get(id);
    return value is String ? value : null;
  }

  Future<void> put(String id, String body) async {
    if (body.isEmpty) return;
    await _box.put(id, body);
    final overflow = _box.length - maxEntries;
    if (overflow > 0) {
      await _box.deleteAll(_box.keys.take(overflow).toList());
    }
  }
}
