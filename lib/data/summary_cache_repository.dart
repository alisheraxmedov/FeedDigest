import 'package:hive_ce/hive.dart';
import '../models/ai_summary.dart';

/// Disk cache for AI summaries, keyed by `${articleId}-${lang}-${depth}`. Caps
/// the box at [maxEntries]: Hive preserves insertion order, so on overflow the
/// oldest entries are evicted first (FIFO) — the box can't grow unbounded.
class SummaryCacheRepository {
  SummaryCacheRepository(this._box, {this.maxEntries = 200});

  final Box<dynamic> _box;
  final int maxEntries;

  AiSummary? get(String postId) {
    final value = _box.get(postId);
    if (value == null) return null;
    return AiSummary.fromJson(Map<String, dynamic>.from(value as Map));
  }

  Future<void> put(AiSummary summary) async {
    await _box.put(summary.postId, summary.toJson());
    await _evictOverflow();
  }

  Future<void> _evictOverflow() async {
    final overflow = _box.length - maxEntries;
    if (overflow <= 0) return;
    final oldest = _box.keys.take(overflow).toList();
    await _box.deleteAll(oldest);
  }
}
