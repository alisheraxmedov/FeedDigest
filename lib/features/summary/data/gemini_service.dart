import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/env.dart';
import '../../../core/network/dio_client.dart';
import '../../feed/data/models/reddit_comment.dart';
import '../../feed/data/models/reddit_post.dart';
import 'ai_summary.dart';

/// Produces a two-part, plain-language **Uzbek** summary of a Reddit post and
/// its discussion (top comments), returned as separate fields.
abstract interface class GeminiService {
  Future<AiSummary> summarize(RedditPost post, List<RedditComment> comments);
}

/// Builds the localized prompt. Gemini is asked to return strict JSON so the
/// two sections can be shown separately.
String buildSummaryPrompt(RedditPost post, List<RedditComment> comments) {
  final commentsBlock = comments.isEmpty
      ? '(Izohlar yo‘q)'
      : comments
          .take(12)
          .map((c) => '- (${c.score} ovoz) ${c.body}')
          .join('\n');

  return '''
Siz Reddit postlarini o'zbek tiliga sodda tushuntiruvchi yordamchisiz.

Quyidagi post va uning eng yaxshi izohlarini tahlil qiling va NATIJANI FAQAT
JSON ko'rinishida qaytaring (boshqa hech narsa yozmang):

{
  "post_summary": "<postning o'zbek tilida 3-4 jumlali qisqa xulosasi>",
  "comments_summary": "<izohlardagi asosiy fikrlar va munozaraning o'zbek tilida 2-3 jumlali xulosasi; izohlar bo'lmasa: 'Hozircha izohlar yo'q'>"
}

Qoidalar:
- Faqat o'zbek tilida yozing.
- Sodda, tushunarli til ishlating; texnik atamalarni izohlang.
- Kirish so'zlarisiz, to'g'ridan-to'g'ri mazmunni yozing.

=== POST ===
Sarlavha: ${post.title}
Subreddit: r/${post.subreddit}
Matn: ${post.summarizableText}

=== ENG YAXSHI IZOHLAR ===
$commentsBlock
''';
}

/// Real Gemini implementation over the stable REST `generateContent` endpoint.
class GeminiServiceImpl implements GeminiService {
  GeminiServiceImpl({Dio? dio}) : _dio = dio ?? DioClient.create();

  final Dio _dio;

  @override
  Future<AiSummary> summarize(
    RedditPost post,
    List<RedditComment> comments,
  ) async {
    final key = Env.geminiApiKey;
    if (key.isEmpty) {
      throw const ApiException(
        'Gemini API kaliti topilmadi. `.env` fayliga GEMINI_API_KEY qo‘shing.',
      );
    }

    final url =
        '${AppConfig.geminiBase}/models/${Env.geminiModel}:generateContent';

    try {
      final response = await _dio.post<dynamic>(
        url,
        queryParameters: {'key': key},
        data: {
          'contents': [
            {
              'parts': [
                {'text': buildSummaryPrompt(post, comments)},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.4,
            'maxOutputTokens': 800,
            'responseMimeType': 'application/json',
          },
        },
        options: Options(contentType: Headers.jsonContentType),
      );

      final status = response.statusCode ?? 0;
      if (status != 200) throw _mapStatus(status, response.data);

      final text = _extractText(response.data);
      if (text == null || text.trim().isEmpty) {
        throw const ApiException(
            'AI bo‘sh javob qaytardi. Qayta urinib ko‘ring.');
      }
      return AiSummary.fromGeminiText(text);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw _mapStatus(e.response?.statusCode ?? 0, e.response?.data);
    }
  }

  String? _extractText(dynamic data) {
    if (data is! Map) return null;
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final content = (candidates.first as Map)['content'];
    if (content is! Map) return null;
    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return null;
    final text = (parts.first as Map)['text'];
    return text is String ? text : null;
  }

  ApiException _mapStatus(int status, dynamic body) {
    final apiMessage = body is Map && body['error'] is Map
        ? (body['error'] as Map)['message']?.toString()
        : null;
    switch (status) {
      case 400:
        return ApiException(
          'So‘rov noto‘g‘ri — API kaliti yoki model nomini tekshiring.'
          '${apiMessage != null ? '\n$apiMessage' : ''}',
          statusCode: 400,
        );
      case 403:
        return const ApiException(
          'API kalit ruxsat bermadi (403). Kalitni tekshiring.',
          statusCode: 403,
        );
      case 429:
        return const ApiException(
          'Gemini so‘rov limiti tugadi (429). Birozdan so‘ng urining.',
          statusCode: 429,
        );
      default:
        return ApiException(
          'AI bilan bog‘lanishda xatolik${status > 0 ? ' ($status)' : ''}.',
          statusCode: status,
        );
    }
  }
}

/// Offline stand-in used when no Gemini key is configured. Returns a clearly
/// labelled DEMO summary so the feature's UI is fully demoable — it never
/// pretends to be a real AI response.
class MockGeminiService implements GeminiService {
  const MockGeminiService();

  @override
  Future<AiSummary> summarize(
    RedditPost post,
    List<RedditComment> comments,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return AiSummary(
      postSummary: '🧪 (Namuna / demo — haqiqiy AI emas)\n\n'
          'Ushbu post "${post.title}" mavzusida bo‘lib, r/${post.subreddit} '
          'hamjamiyatida muhokama qilinmoqda. Haqiqiy o‘zbekcha AI xulosa '
          'olish uchun `.env` fayliga GEMINI_API_KEY ni qo‘shing.',
      commentsSummary: comments.isEmpty
          ? 'Hozircha izohlar yo‘q.'
          : '🧪 (Namuna) Izohlarda ${comments.length} ta fikr bildirilgan: '
              'ba‘zilar yondashuvni maqtagan, ba‘zilari esa muqobil yechimlarni '
              'taklif qilgan. Eng ko‘p ovoz olgan izoh muallifning '
              'qo‘shimchasi bo‘lgan.',
    );
  }
}
