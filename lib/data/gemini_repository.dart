/*
GeminiRepository summarizes an article with the Gemini API in the language the
user picked for AI summaries (langCode: 'uz' | 'ru' | 'en'). The instruction is
built per language so the model answers in that language. Failures throw a
GeminiException carrying a stable code the UI maps to a localized message.
*/
import 'package:dio/dio.dart';
import '../core/config/app_config.dart';
import '../models/article.dart';
import '../models/chat_message.dart';
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

  static const Map<String, String> _digestIntro = {
    'uz':
        "Quyida bugungi eng muhim dasturlash/texnologiya yangiliklari ro'yxati. "
        "Ularni o'zbek tilida yaxlit kunlik digest qilib umumlashtir. "
        "Boshida bitta umumiy sarlavha (##) va bir jumlalik kirish ber. "
        "Keyin har bir xabarni alohida ko'rsat: sarlavhasi (###), so'ng 1-2 "
        "jumlada nima haqida ekani va nega muhimligi. "
        "Markdown ishlat (##, ###, **, -). Faqat o'zbek tilida javob qaytar.",
    'ru':
        'Ниже список самых важных новостей разработки/технологий за сегодня. '
        'Сделай из них цельный ежедневный дайджест на русском языке. '
        'В начале дай общий заголовок (##) и вводное предложение. '
        'Затем по каждой новости: заголовок (###), затем 1-2 предложения о том, '
        'о чём она и почему важна. '
        'Используй Markdown (##, ###, **, -). Отвечай только на русском языке.',
    'en':
        'Below is a list of today\'s most important dev/technology news. '
        'Turn them into one cohesive daily digest in English. '
        'Start with an overall heading (##) and a one-sentence intro. '
        'Then for each story: a heading (###), then 1-2 sentences on what it is '
        'and why it matters. '
        'Use Markdown (##, ###, **, -). Respond only in English.',
  };

  /// Summarizes several articles into a single daily digest in one API call.
  /// Feeds only titles + short snippets (not full bodies) to keep the request
  /// within context and spare the user's quota.
  Future<String> digest(
    List<Article> articles, {
    required String langCode,
  }) async {
    final key = await _settings.getGeminiKey();
    if (key == null || key.isEmpty) {
      throw GeminiException('no_key');
    }
    final intro = _digestIntro[langCode] ?? _digestIntro['uz']!;
    final buf = StringBuffer();
    for (var i = 0; i < articles.length; i++) {
      final a = articles[i];
      final snip = a.body.replaceAll(RegExp(r'<[^>]+>'), ' ').trim();
      final short = snip.length > 240 ? '${snip.substring(0, 240)}…' : snip;
      buf.writeln('${i + 1}. [${a.source}] ${a.title}');
      if (short.isNotEmpty) buf.writeln('   $short');
    }
    final prompt = '$intro\n\n$buf';
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

  static const Map<String, String> _translateInstr = {
    'uz':
        "Quyidagi maqolani to'liq o'zbek tiliga tarjima qil. Markdown "
        "formatini saqlab qol; kod bloklari (```), inline kod va URL'larni "
        "tarjima QILMA — o'zgartirmasdan qoldir. Faqat tarjimani qaytar, "
        "boshqa hech qanday izohsiz.",
    'ru':
        'Переведи следующую статью полностью на русский язык. Сохрани '
        'форматирование Markdown; НЕ переводи блоки кода (```), инлайн-код и '
        'URL — оставь их без изменений. Верни только перевод, без пояснений.',
    'en':
        'Translate the following article fully into English. Preserve Markdown '
        'formatting; do NOT translate code blocks (```), inline code, or URLs — '
        'leave them unchanged. Return only the translation, no extra commentary.',
  };

  /// Translates an article body into [targetLangCode], preserving Markdown and
  /// leaving code/URLs untouched. Aimed at the underserved uz/ru dev audience
  /// reading English-only Hacker News / dev.to content.
  Future<String> translate(
    String text, {
    required String targetLangCode,
  }) async {
    final key = await _settings.getGeminiKey();
    if (key == null || key.isEmpty) {
      throw GeminiException('no_key');
    }
    final instruction =
        _translateInstr[targetLangCode] ?? _translateInstr['uz']!;
    final prompt = '$instruction\n\n$text';
    try {
      final resp = await _dio.post<dynamic>(
        '${AppConfig.geminiEndpoint}/${AppConfig.geminiModel}:generateContent',
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
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

  static const Map<String, String> _chatSystem = {
    'uz':
        "Sen foydalanuvchiga QUYIDA berilgan maqola bo'yicha yordam beradigan "
        "yordamchisan. Faqat maqola mazmuniga tayangan holda o'zbek tilida "
        "qisqa va aniq javob ber. Agar javob maqolada bo'lmasa, buni ochiq ayt.",
    'ru':
        'Ты ассистент, который помогает пользователю по статье, приведённой '
        'НИЖЕ. Отвечай кратко и по делу на русском языке, опираясь только на '
        'содержание статьи. Если ответа в статье нет — прямо скажи об этом.',
    'en':
        'You are an assistant helping the user with the article provided BELOW. '
        'Answer concisely in English, grounded only in the article content. If '
        'the answer is not in the article, say so plainly.',
  };

  /// Multi-turn Q&A grounded in a single article. The article text is passed as
  /// a system instruction (truncated to bound context/quota); [history] carries
  /// the prior turns and [question] is the new user message.
  Future<String> chat({
    required Article article,
    required String articleBody,
    required List<ChatMessage> history,
    required String question,
    required String langCode,
  }) async {
    final key = await _settings.getGeminiKey();
    if (key == null || key.isEmpty) {
      throw GeminiException('no_key');
    }
    final system = _chatSystem[langCode] ?? _chatSystem['uz']!;
    final context = articleBody.length > 8000
        ? articleBody.substring(0, 8000)
        : articleBody;
    final contents = <Map<String, dynamic>>[
      for (final m in history)
        {
          'role': m.isUser ? 'user' : 'model',
          'parts': [
            {'text': m.text},
          ],
        },
      {
        'role': 'user',
        'parts': [
          {'text': question},
        ],
      },
    ];
    try {
      final resp = await _dio.post<dynamic>(
        '${AppConfig.geminiEndpoint}/${AppConfig.geminiModel}:generateContent',
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          headers: {'x-goog-api-key': key, 'Content-Type': 'application/json'},
        ),
        data: {
          'system_instruction': {
            'parts': [
              {'text': '$system\n\nTitle: ${article.title}\n\n$context'},
            ],
          },
          'contents': contents,
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
