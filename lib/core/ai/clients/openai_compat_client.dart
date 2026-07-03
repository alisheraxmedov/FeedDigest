/*
One client for every OpenAI-compatible backend (OpenAI, DeepSeek, xAI): they
share POST {base}/chat/completions with Bearer auth and the same
choices[0].message.content response. baseUrl+model come from the caller so
three providers reuse this single class.
*/
import 'package:dio/dio.dart';
import '../ai_client.dart';

class OpenAiCompatClient implements AiClient {
  OpenAiCompatClient(this._dio, {required this.baseUrl, required this.model});

  final Dio _dio;
  final String baseUrl;
  final String model;

  @override
  Future<String> complete({
    required String apiKey,
    String? system,
    required List<AiMessage> messages,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      final resp = await _dio.post<dynamic>(
        '$baseUrl/chat/completions',
        options: Options(
          receiveTimeout: timeout,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': model,
          'messages': [
            if (system != null) {'role': 'system', 'content': system},
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
      final choice = data['choices'][0];
      if (choice['finish_reason'] == 'content_filter') {
        throw AiException('blocked', 'content_filter');
      }
      final text = choice['message']['content'];
      if (text is String && text.trim().isNotEmpty) return text.trim();
      if (text is String) throw AiException('empty');
    } on AiException {
      rethrow;
    } catch (_) {
      throw AiException('parse');
    }
    throw AiException('empty');
  }
}
