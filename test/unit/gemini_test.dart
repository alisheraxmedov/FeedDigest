import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/data/gemini_repository.dart';

void main() {
  test('extractText pulls the candidate text', () {
    final data = {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': '  Bu xulosa.  '},
            ],
          },
        },
      ],
    };
    expect(GeminiRepository.extractText(data), 'Bu xulosa.');
  });

  test('extractText throws on bad shape', () {
    expect(
      () => GeminiRepository.extractText(const {}),
      throwsA(isA<GeminiException>()),
    );
  });
}
