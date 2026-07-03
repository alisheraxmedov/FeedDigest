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

  test('extractText maps a SAFETY finishReason to blocked, not parse', () {
    final data = {
      'candidates': [
        {
          'finishReason': 'SAFETY',
          'content': {'role': 'model'},
        },
      ],
    };
    expect(
      () => GeminiRepository.extractText(data),
      throwsA(isA<GeminiException>().having((e) => e.code, 'code', 'blocked')),
    );
  });

  test('extractText maps a RECITATION finishReason to blocked', () {
    final data = {
      'candidates': [
        {'finishReason': 'RECITATION'},
      ],
    };
    expect(
      () => GeminiRepository.extractText(data),
      throwsA(isA<GeminiException>().having((e) => e.code, 'code', 'blocked')),
    );
  });

  test('extractText still returns text when finishReason is STOP', () {
    final data = {
      'candidates': [
        {
          'finishReason': 'STOP',
          'content': {
            'parts': [
              {'text': 'ok'},
            ],
          },
        },
      ],
    };
    expect(GeminiRepository.extractText(data), 'ok');
  });
}
