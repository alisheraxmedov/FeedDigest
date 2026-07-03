import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/core/ai/ai_provider.dart';

void main() {
  test('fromId resolves each provider and falls back to gemini', () {
    expect(AiProvider.fromId('openai'), AiProvider.openai);
    expect(AiProvider.fromId('claude'), AiProvider.claude);
    expect(AiProvider.fromId('deepseek'), AiProvider.deepseek);
    expect(AiProvider.fromId('grok'), AiProvider.grok);
    expect(AiProvider.fromId('gemini'), AiProvider.gemini);
    expect(AiProvider.fromId(null), AiProvider.gemini);
    expect(AiProvider.fromId('bogus'), AiProvider.gemini);
  });

  test('storageKey keeps the legacy gemini key name', () {
    expect(AiProvider.gemini.storageKey, 'gemini_api_key');
    expect(AiProvider.openai.storageKey, 'ai_key_openai');
    expect(AiProvider.claude.storageKey, 'ai_key_claude');
    expect(AiProvider.deepseek.storageKey, 'ai_key_deepseek');
    expect(AiProvider.grok.storageKey, 'ai_key_grok');
  });

  test('every provider carries a non-empty model id', () {
    for (final p in AiProvider.values) {
      expect(p.model, isNotEmpty);
    }
  });
}
