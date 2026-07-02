import 'package:hive_ce/hive.dart';

/// Caches resolved article bodies so a previously opened article reads offline.
/// Keyed by article id, capped at [maxEntries]; on overflow the oldest bodies
/// (by write time) are evicted first. Values are `{body, cachedAt}` envelopes:
/// Hive's `Box.keys` is sorted lexicographically (not by insertion order), so
/// key order can't drive FIFO — the stamp is the source of truth. Legacy
/// plain-string values (written before the envelope) are still read.
class ArticleBodyCacheRepository {
  ArticleBodyCacheRepository(
    this._box, {
    this.maxEntries = 200,
    DateTime Function() now = DateTime.now,
  }) : _now = now;

  final Box<dynamic> _box;
  final int maxEntries;
  final DateTime Function() _now;

  String? get(String id) {
    final value = _box.get(id);
    if (value is String) return value; // legacy plain-string entry
    if (value is Map) return value['body'] as String?;
    return null;
  }

  Future<void> put(String id, String body) async {
    if (body.isEmpty) return;
    await _box.put(id, {
      'body': body,
      'cachedAt': _now().millisecondsSinceEpoch,
    });
    await _evictOverflow();
  }

  Future<void> _evictOverflow() async {
    final overflow = _box.length - maxEntries;
    if (overflow <= 0) return;
    final keys = _box.keys.toList()
      ..sort((a, b) => _cachedAt(a).compareTo(_cachedAt(b)));
    await _box.deleteAll(keys.take(overflow));
  }

  /// Write-time stamp for [key]; legacy string entries have none, so they sort
  /// oldest and are evicted first.
  int _cachedAt(dynamic key) {
    final value = _box.get(key);
    if (value is Map) return (value['cachedAt'] as num?)?.toInt() ?? 0;
    return 0;
  }
}
