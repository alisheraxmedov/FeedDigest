import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/models/ai_summary.dart';

void main() {
  test('round-trips through json', () {
    const s = AiSummary(postId: 'abc', summary: 'Salom');
    final back = AiSummary.fromJson(s.toJson());
    expect(back.postId, 'abc');
    expect(back.summary, 'Salom');
  });

  test('tolerates missing fields', () {
    final s = AiSummary.fromJson(const {});
    expect(s.postId, '');
    expect(s.summary, '');
  });
}
