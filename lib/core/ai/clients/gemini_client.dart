/*
Native Gemini generateContent client. Also owns voiceQuery — inline audio
understanding is Gemini-only, which is why voice search is gated on the
gemini provider. extractText maps Gemini safety blocks to 'blocked'.
*/
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../ai_client.dart';

class GeminiClient implements AiClient {
  GeminiClient(this._dio);

  final Dio _dio;

  static String get _url =>
      '${AppConfig.geminiEndpoint}/${AppConfig.geminiModel}:generateContent';

  @override
  Future<String> complete({
    required String apiKey,
    String? system,
    required List<AiMessage> messages,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      final resp = await _dio.post<dynamic>(
        _url,
        options: Options(
          receiveTimeout: timeout,
          headers: {
            'x-goog-api-key': apiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          if (system != null)
            'system_instruction': {
              'parts': [
                {'text': system},
              ],
            },
          'contents': [
            for (final m in messages)
              {
                'role': m.isUser ? 'user' : 'model',
                'parts': [
                  {'text': m.text},
                ],
              },
          ],
        },
      );
      return extractText(resp.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  static const String _voiceQueryPrompt =
      'You are a search-query extractor for a tech-news reader (Hacker News + '
      'dev.to). The user recorded a short spoken request (in Uzbek, Russian, or '
      'English) asking for articles about some topic. Understand the audio and '
      'output ONLY a concise search query in English — the topic keywords they '
      'want (1-4 words), lowercase, no punctuation, no quotes, no extra text. '
      'If the audio is unclear or silent, output nothing.';

  /// Turns a short spoken request (inline audio) into a concise English search
  /// query. Gemini-only: no other provider accepts inline audio.
  Future<String> voiceQuery(
    List<int> audioBytes, {
    required String apiKey,
    required String mimeType,
  }) async {
    try {
      final resp = await _dio.post<dynamic>(
        _url,
        options: Options(
          receiveTimeout: const Duration(seconds: 45),
          headers: {
            'x-goog-api-key': apiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'contents': [
            {
              'parts': [
                {'text': _voiceQueryPrompt},
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Encode(audioBytes),
                  },
                },
              ],
            },
          ],
        },
      );
      return extractText(resp.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Candidate `finishReason` values that mean the model refused to answer
  /// (an output-side block) rather than finishing normally.
  static const Set<String> _blockedFinishReasons = {
    'SAFETY',
    'RECITATION',
    'PROHIBITED_CONTENT',
    'BLOCKLIST',
    'SPII',
  };

  static String extractText(dynamic data) {
    try {
      if (data is Map) {
        final blockReason = data['promptFeedback']?['blockReason'];
        if (blockReason != null) {
          throw AiException('blocked', '$blockReason');
        }
        final candidates = data['candidates'];
        if (candidates is List && candidates.isEmpty) {
          throw AiException('blocked');
        }
        // Output-side block: the candidate stopped for a safety/recitation
        // reason and carries no usable content. Without this it would fall
        // through to the parts access below and be misreported as 'parse'.
        if (candidates is List && candidates.isNotEmpty) {
          final first = candidates.first;
          final finish = first is Map ? first['finishReason'] : null;
          if (finish is String && _blockedFinishReasons.contains(finish)) {
            throw AiException('blocked', finish);
          }
        }
      }
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      if (text is String && text.trim().isNotEmpty) return text.trim();
    } on AiException {
      rethrow;
    } catch (_) {
      throw AiException('parse');
    }
    throw AiException('empty');
  }
}
