/*
fetchReadablePage — shared readable-body fetch for sources whose feed carries no
full article text (Hacker News link posts, Lobsters, RSS). Fetches the linked
page with a browser User-Agent and reduces it to readable text via HtmlReadable.
Returns '' on a non-http url or any failure so callers can fall back to the feed
snippet.
*/
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'html_readable.dart';

Future<String> fetchReadablePage(Dio dio, String url) async {
  if (!url.startsWith('http')) return '';
  try {
    final resp = await dio.getUri<String>(
      Uri.parse(url),
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(seconds: 20),
        followRedirects: true,
        headers: {'User-Agent': AppConfig.readerUserAgent},
        validateStatus: (status) => status != null && status >= 200 && status < 400,
      ),
    );
    return HtmlReadable.extract(resp.data ?? '');
  } catch (_) {
    return '';
  }
}
