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

  static const Map<String, String> _detailed = {
    'uz':
        "Quyidagi maqolani o'zbek tilida batafsil xulosa qil. "
        "Maqoladagi har bir bo'lim, mavzu va muhim fikrni qamrab ol. "
        "Asosiy g'oyalar, dalillar, misollar va xulosalarni saqlab qol. "
        "Asl ma'no yo'qolmasligi kerak — maqolada nima haqida gap ketgani to'liq aks etishi lozim. "
        "Qisqa va yuzaki emas, mazmunli va to'liq xulosa ber. "
        "Javobni Markdown formatida qaytar: sarlavhalar (##), qalin matn (**), "
        "ro'yxatlar (-) va paragraflardan foydalan. "
        "Faqat o'zbek tilida javob qaytar.",
    'ru':
        'Подробно изложи следующую статью на русском языке. '
        'Охвати каждый раздел, тему и важную мысль статьи. '
        'Сохрани ключевые идеи, аргументы, примеры и выводы. '
        'Исходный смысл не должен быть утерян — в резюме должно быть полностью отражено, о чём идёт речь в статье. '
        'Дай содержательное и полное резюме, а не краткое и поверхностное. '
        'Верни ответ в формате Markdown: используй заголовки (##), жирный текст (**), '
        'списки (-) и абзацы. '
        'Отвечай только на русском языке.',
    'en':
        'Summarize the following article in detail in English. '
        'Cover every section, topic, and important point in the article. '
        'Preserve key ideas, arguments, examples, and conclusions. '
        'The original meaning must not be lost — the summary should fully reflect what the article is about. '
        'Provide a substantive and complete summary, not a brief and superficial one. '
        'Return the response in Markdown format: use headings (##), bold text (**), '
        'lists (-), and paragraphs. '
        'Respond only in English.',
  };

  static const Map<String, String> _brief = {
    'uz':
        "Quyidagi maqolani o'zbek tilida juda qisqa (TL;DR) xulosa qil. "
        "Faqat 3-5 ta eng muhim fikrni bullet ro'yxati (-) ko'rinishida ber. "
        "Har bir band bitta jumla bo'lsin, ortiqcha tafsilotsiz. "
        "Javobni Markdown formatida qaytar. Faqat o'zbek tilida javob qaytar.",
    'ru':
        'Сделай очень краткое (TL;DR) резюме следующей статьи на русском языке. '
        'Дай только 3-5 самых важных мыслей в виде маркированного списка (-). '
        'Каждый пункт — одно предложение, без лишних деталей. '
        'Верни ответ в формате Markdown. Отвечай только на русском языке.',
    'en':
        'Write a very short (TL;DR) summary of the following article in English. '
        'Give only the 3-5 most important points as a bulleted list (-). '
        'Each point is one sentence, no extra detail. '
        'Return the response in Markdown format. Respond only in English.',
  };

  Future<String> summarize(
    Article article, {
    required String langCode,
    bool brief = false,
  }) async {
    final key = await _settings.getGeminiKey();
    if (key == null || key.isEmpty) {
      throw GeminiException('no_key');
    }
    final set = brief ? _brief : _detailed;
    final instruction = set[langCode] ?? set['uz']!;
    final text = article.contentText.replaceAll(RegExp(r'<[^>]+>'), ' ').trim();
    final prompt = '$instruction\n\nTitle: ${article.title}\n\nText: $text';
    try {
      final resp = await _dio.post<dynamic>(
        '${AppConfig.geminiEndpoint}/${AppConfig.geminiModel}:generateContent',
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          headers: {'x-goog-api-key': key, 'Content-Type': 'application/json'},
        ),
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        },
      );
      return extractText(resp.data);
    } on DioException catch (e) {
      throw GeminiException('request', e.message ?? '');
    }
  }

  static String extractText(dynamic data) {
    try {
      if (data is Map) {
        final blockReason = data['promptFeedback']?['blockReason'];
        if (blockReason != null) {
          throw GeminiException('blocked', '$blockReason');
        }
        final candidates = data['candidates'];
        if (candidates is List && candidates.isEmpty) {
          throw GeminiException('blocked');
        }
      }
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      if (text is String && text.trim().isNotEmpty) return text.trim();
    } on GeminiException {
      rethrow;
    } catch (_) {
      throw GeminiException('parse');
    }
    throw GeminiException('empty');
  }
}
