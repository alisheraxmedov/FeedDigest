import 'package:hive_ce/hive.dart';
import '../models/ai_summary.dart';

class SummaryCacheRepository {
  SummaryCacheRepository(this._box);

  final Box<dynamic> _box;

  AiSummary? get(String postId) {
    final value = _box.get(postId);
    if (value == null) return null;
    return AiSummary.fromJson(Map<String, dynamic>.from(value as Map));
  }

  Future<void> put(AiSummary summary) =>
      _box.put(summary.postId, summary.toJson());
}
