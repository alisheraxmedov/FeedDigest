/*
Native Anthropic Messages API client (Dart has no official Anthropic SDK, so
raw HTTP via the shared dio instance is the sanctioned path). Claude's safety
classifiers surface as stop_reason "refusal" — mapped to the same 'blocked'
code the UI already localizes.
*/
import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../ai_client.dart';
import '../ai_provider.dart';

class AnthropicClient implements AiClient {
  AnthropicClient(this._dio);

  final Dio _dio;

  static const String _version = '2023-06-01';
  static const int _maxTokens = 8192;

  @override
  Future<String> complete({
    required String apiKey,
    String? system,
    required List<AiMessage> messages,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      final resp = await _dio.post<dynamic>(
        AppConfig.anthropicEndpoint,
        options: Options(
          receiveTimeout: timeout,
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': _version,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': AiProvider.claude.model,
          'max_tokens': _maxTokens,
          if (system != null) 'system': system,
          'messages': [
            for (final m in messages)
              {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
          ],
        },
      );
      return extractText(resp.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  static String extractText(dynamic data) {
    try {
      if (data['stop_reason'] == 'refusal') {
        throw AiException('blocked', 'refusal');
      }
      final content = data['content'];
      if (content is List) {
        final buf = StringBuffer();
        for (final block in content) {
          if (block is Map && block['type'] == 'text') {
            buf.write(block['text']);
          }
        }
        final text = buf.toString().trim();
        if (text.isNotEmpty) return text;
        throw AiException('empty');
      }
    } on AiException {
      rethrow;
    } catch (_) {
      throw AiException('parse');
    }
    throw AiException('parse');
  }
}
