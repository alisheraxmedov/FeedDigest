import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/core/ai/ai_client.dart';
import 'package:feeddigest/core/ai/clients/anthropic_client.dart';
import 'package:feeddigest/core/ai/clients/openai_compat_client.dart';

/// Hand-rolled adapter: captures the request and returns a canned JSON body,
/// so request shape and header handling are testable without a mock package.
class CapturingAdapter implements HttpClientAdapter {
  CapturingAdapter(this.statusCode, this.body);

  final int statusCode;
  final String body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio dioWith(CapturingAdapter adapter) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  return dio;
}

void main() {
  group('OpenAiCompatClient.extractText', () {
    test('pulls choices[0].message.content', () {
      final data = {
        'choices': [
          {
            'finish_reason': 'stop',
            'message': {'role': 'assistant', 'content': '  Xulosa.  '},
          },
        ],
      };
      expect(OpenAiCompatClient.extractText(data), 'Xulosa.');
    });

    test('maps content_filter finish to blocked', () {
      final data = {
        'choices': [
          {
            'finish_reason': 'content_filter',
            'message': {'role': 'assistant', 'content': ''},
          },
        ],
      };
      expect(
        () => OpenAiCompatClient.extractText(data),
        throwsA(isA<AiException>().having((e) => e.code, 'code', 'blocked')),
      );
    });

    test('throws parse on bad shape and empty on blank text', () {
      expect(
        () => OpenAiCompatClient.extractText(const {}),
        throwsA(isA<AiException>().having((e) => e.code, 'code', 'parse')),
      );
      final blank = {
        'choices': [
          {
            'finish_reason': 'stop',
            'message': {'content': '   '},
          },
        ],
      };
      expect(
        () => OpenAiCompatClient.extractText(blank),
        throwsA(isA<AiException>().having((e) => e.code, 'code', 'empty')),
      );
    });
  });

  group('OpenAiCompatClient.complete', () {
    test('sends bearer auth, model, and system+history payload', () async {
      final adapter = CapturingAdapter(
        200,
        jsonEncode({
          'choices': [
            {
              'finish_reason': 'stop',
              'message': {'content': 'ok'},
            },
          ],
        }),
      );
      final client = OpenAiCompatClient(
        dioWith(adapter),
        baseUrl: 'https://api.deepseek.com',
        model: 'deepseek-v4-flash',
      );
      final out = await client.complete(
        apiKey: 'k123',
        system: 'sys',
        messages: const [
          AiMessage.user('savol'),
          AiMessage.model('javob'),
          AiMessage.user('yana'),
        ],
      );
      expect(out, 'ok');
      final req = adapter.lastRequest!;
      expect(req.uri.toString(), 'https://api.deepseek.com/chat/completions');
      expect(req.headers['Authorization'], 'Bearer k123');
      final body = req.data as Map<String, dynamic>;
      expect(body['model'], 'deepseek-v4-flash');
      final msgs = body['messages'] as List;
      expect(msgs.first, {'role': 'system', 'content': 'sys'});
      expect(msgs[1], {'role': 'user', 'content': 'savol'});
      expect(msgs[2], {'role': 'assistant', 'content': 'javob'});
      expect(msgs[3], {'role': 'user', 'content': 'yana'});
    });

    test('maps 401 to auth and 429 to rate_limit', () async {
      for (final (status, code) in [(401, 'auth'), (429, 'rate_limit')]) {
        final adapter = CapturingAdapter(status, '{"error":{}}');
        final client = OpenAiCompatClient(
          dioWith(adapter),
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-4.1-mini',
        );
        await expectLater(
          client.complete(
            apiKey: 'bad',
            messages: const [AiMessage.user('x')],
          ),
          throwsA(isA<AiException>().having((e) => e.code, 'code', code)),
        );
      }
    });
  });

  group('AnthropicClient.extractText', () {
    test('joins text blocks', () {
      final data = {
        'stop_reason': 'end_turn',
        'content': [
          {'type': 'text', 'text': 'Bir. '},
          {'type': 'text', 'text': 'Ikki.'},
        ],
      };
      expect(AnthropicClient.extractText(data), 'Bir. Ikki.');
    });

    test('maps refusal stop_reason to blocked', () {
      final data = {'stop_reason': 'refusal', 'content': <dynamic>[]};
      expect(
        () => AnthropicClient.extractText(data),
        throwsA(isA<AiException>().having((e) => e.code, 'code', 'blocked')),
      );
    });

    test('throws parse on bad shape and empty on no text', () {
      expect(
        () => AnthropicClient.extractText('nonsense'),
        throwsA(isA<AiException>().having((e) => e.code, 'code', 'parse')),
      );
      expect(
        () => AnthropicClient.extractText({
          'stop_reason': 'end_turn',
          'content': <dynamic>[],
        }),
        throwsA(isA<AiException>().having((e) => e.code, 'code', 'empty')),
      );
    });
  });

  group('AnthropicClient.complete', () {
    test('sends x-api-key, version header, system and messages', () async {
      final adapter = CapturingAdapter(
        200,
        jsonEncode({
          'stop_reason': 'end_turn',
          'content': [
            {'type': 'text', 'text': 'ok'},
          ],
        }),
      );
      final client = AnthropicClient(dioWith(adapter));
      final out = await client.complete(
        apiKey: 'sk-ant-1',
        system: 'sys',
        messages: const [AiMessage.user('savol')],
      );
      expect(out, 'ok');
      final req = adapter.lastRequest!;
      expect(req.uri.toString(), 'https://api.anthropic.com/v1/messages');
      expect(req.headers['x-api-key'], 'sk-ant-1');
      expect(req.headers['anthropic-version'], '2023-06-01');
      final body = req.data as Map<String, dynamic>;
      expect(body['model'], 'claude-haiku-4-5');
      expect(body['system'], 'sys');
      expect(body['max_tokens'], isPositive);
      expect((body['messages'] as List).single, {
        'role': 'user',
        'content': 'savol',
      });
    });
  });
}
