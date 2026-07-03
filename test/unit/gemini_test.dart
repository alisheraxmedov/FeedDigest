import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/core/ai/ai_client.dart';
import 'package:feeddigest/core/ai/clients/gemini_client.dart';

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
    expect(GeminiClient.extractText(data), 'Bu xulosa.');
  });

  test('extractText throws on bad shape', () {
    expect(
      () => GeminiClient.extractText(const {}),
      throwsA(isA<AiException>()),
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
      () => GeminiClient.extractText(data),
      throwsA(isA<AiException>().having((e) => e.code, 'code', 'blocked')),
    );
  });

  test('extractText maps a RECITATION finishReason to blocked', () {
    final data = {
      'candidates': [
        {'finishReason': 'RECITATION'},
      ],
    };
    expect(
      () => GeminiClient.extractText(data),
      throwsA(isA<AiException>().having((e) => e.code, 'code', 'blocked')),
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
    expect(GeminiClient.extractText(data), 'ok');
  });
}
