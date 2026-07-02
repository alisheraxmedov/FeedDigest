import 'package:hive_ce/hive.dart';
import '../models/ai_summary.dart';

/// Disk cache for AI summaries, keyed by `${articleId}-${lang}-${depth}`. Caps
/// the box at [maxEntries]; on overflow the oldest entries (by write time) are
/// evicted first. Each stored value carries a `cachedAt` epoch-ms stamp: Hive's
/// `Box.keys` is sorted lexicographically (not by insertion order), so key
/// order can't be trusted for FIFO — the stamp is the source of truth.
class SummaryCacheRepository {
  SummaryCacheRepository(
    this._box, {
    this.maxEntries = 200,
    DateTime Function() now = DateTime.now,
  }) : _now = now;

  final Box<dynamic> _box;
  final int maxEntries;
  final DateTime Function() _now;

  AiSummary? get(String postId) {
    final value = _box.get(postId);
    if (value == null) return null;
    return AiSummary.fromJson(Map<String, dynamic>.from(value as Map));
  }

  Future<void> put(AiSummary summary) async {
    final value = summary.toJson()
      ..['cachedAt'] = _now().millisecondsSinceEpoch;
    await _box.put(summary.postId, value);
    await _evictOverflow();
  }

  Future<void> _evictOverflow() async {
    final overflow = _box.length - maxEntries;
    if (overflow <= 0) return;
    final keys = _box.keys.toList()
      ..sort((a, b) => _cachedAt(a).compareTo(_cachedAt(b)));
    await _box.deleteAll(keys.take(overflow));
  }

  /// Write-time stamp for [key]; legacy entries with no stamp sort oldest.
  int _cachedAt(dynamic key) {
    final value = _box.get(key);
    if (value is Map) return (value['cachedAt'] as num?)?.toInt() ?? 0;
    return 0;
  }
}
