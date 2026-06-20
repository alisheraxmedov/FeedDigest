import 'package:dio/dio.dart';
import '../core/config/app_config.dart';
import '../models/reddit_post.dart';
import 'settings_repository.dart';

class GeminiException implements Exception {
  GeminiException(this.message);
  final String message;
  @override
  String toString() => 'GeminiException: $message';
}

class GeminiRepository {
  GeminiRepository(this._dio, this._settings);

  final Dio _dio;
  final SettingsRepository _settings;

  Future<String> summarize(RedditPost post) async {
    final key = await _settings.getGeminiKey();
    if (key == null || key.isEmpty) {
      throw GeminiException('Gemini API kaliti kiritilmagan');
    }
    final prompt = "Quyidagi inglizcha Reddit postini o'zbek tilida 3-4 "
        "jumlada qisqacha yoz. Faqat o'zbekcha summary qaytar. "
        "Sarlavha: ${post.title}. Matn: ${post.contentText}";
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
  }

  static String extractText(dynamic data) {
    try {
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      if (text is String && text.trim().isNotEmpty) return text.trim();
    } catch (_) {
      throw GeminiException("Javobni o'qib bo'lmadi");
    }
    throw GeminiException("Bo'sh javob");
  }
}
