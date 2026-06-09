import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/features/summary/data/ai_summary.dart';

void main() {
  group('AiSummary.fromGeminiText', () {
    test('parses clean JSON into both fields', () {
      final s = AiSummary.fromGeminiText(
          '{"post_summary": "post xulosa", "comments_summary": "izoh xulosa"}');
      expect(s.postSummary, 'post xulosa');
      expect(s.commentsSummary, 'izoh xulosa');
      expect(s.hasComments, isTrue);
    });

    test('strips a ```json code fence', () {
      const raw = '```json\n'
          '{"post_summary": "p", "comments_summary": "c"}\n'
          '```';
      final s = AiSummary.fromGeminiText(raw);
      expect(s.postSummary, 'p');
      expect(s.commentsSummary, 'c');
    });

    test('falls back to raw text when JSON is malformed', () {
      final s = AiSummary.fromGeminiText('just some plain text');
      expect(s.postSummary, 'just some plain text');
      expect(s.commentsSummary, isEmpty);
      expect(s.hasComments, isFalse);
    });

    test('handles missing comments_summary key', () {
      final s = AiSummary.fromGeminiText('{"post_summary": "only post"}');
      expect(s.postSummary, 'only post');
      expect(s.commentsSummary, isEmpty);
    });
  });
}
