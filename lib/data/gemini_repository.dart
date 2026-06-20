/*
GeminiRepository summarizes an article with the Gemini API in the language the
user picked for AI summaries (langCode: 'uz' | 'ru' | 'en'). The instruction is
built per language so the model answers in that language. Failures throw a
GeminiException carrying a stable code the UI maps to a localized message.
*/
import 'package:dio/dio.dart';
import '../core/config/app_config.dart';
import '../models/article.dart';
import 'settings_repository.dart';

class GeminiException implements Exception {
  GeminiException(this.code, [this.message = '']);

  final String code;
  final String message;

  @override
  String toString() => 'GeminiException($code): $message';
}

class GeminiRepository {
  GeminiRepository(this._dio, this._settings);

  final Dio _dio;
  final SettingsRepository _settings;

  static const Map<String, String> _instructions = {
    'uz': "Quyidagi maqolani o'zbek tilida 3-4 jumlada qisqacha yoz. "
        "Faqat o'zbek tilida javob qaytar.",
    'ru': 'Кратко изложи следующую статью на русском языке в 3-4 предложениях. '
        'Отвечай только на русском языке.',
    'en': 'Summarize the following article in English in 3-4 sentences. '
        'Respond only in English.',
  };

  Future<String> summarize(Article article, {required String langCode}) async {
    final key = await _settings.getGeminiKey();
    if (key == null || key.isEmpty) {
      throw GeminiException('no_key');
    }
    final instruction = _instructions[langCode] ?? _instructions['uz']!;
    final text = article.contentText.replaceAll(RegExp(r'<[^>]+>'), ' ').trim();
    final prompt = '$instruction\n\nTitle: ${article.title}\n\nText: $text';
    try {
      final resp = await _dio.post<dynamic>(
        '${AppConfig.geminiEndpoint}/${AppConfig.geminiModel}:generateContent',
        options: Options(headers: {
          'x-goog-api-key': key,
          'Content-Type': 'application/json',
        }),
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        },
      );
      return extractText(resp.data);
    } on DioException catch (e) {
      throw GeminiException('request', e.message ?? '');
    }
  }

  static String extractText(dynamic data) {
    try {
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      if (text is String && text.trim().isNotEmpty) return text.trim();
    } catch (_) {
      throw GeminiException('parse');
    }
    throw GeminiException('empty');
  }
}
