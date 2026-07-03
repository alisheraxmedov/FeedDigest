/*
RssSource — a generic RSS 2.0 adapter behind the common ArticleSource interface.
One instance per feed (Habr, VC.ru). The feed URL is built per request from a
[FeedUrlBuilder] so a source can query its server by topic (Habr search RSS) or
serve a fixed feed (VC.ru). When the server already filters by topic
([serverFiltersTopic] true) the results are used as-is; otherwise items are
filtered client-side by keyword — with no fallback to unrelated items, so a topic
with no matches yields an empty list rather than misleading general news. Each
item carries only a short description, so fullBody prefers the item's full
content:encoded HTML (cached at parse time) and falls back to fetching the link.
Atom (<entry>) feeds are not handled yet.
*/
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';
import '../config/app_config.dart';
import '../utils/html_readable.dart';
import '../utils/readable_page.dart';
import '../utils/topic_filter.dart';
import '../../models/article.dart';
import 'article_source.dart';

/// Builds the feed URL for a given topic and sort. An empty topic means "no
/// topic selected" (the source's default/latest feed).
typedef FeedUrlBuilder = String Function(String topic, FeedSort sort);

class RssSource implements ArticleSource {
  RssSource(
    this._dio, {
    required FeedSource kind,
    required FeedUrlBuilder urlBuilder,
    bool serverFiltersTopic = false,
  }) : _kind = kind,
       _urlBuilder = urlBuilder,
       _serverFiltersTopic = serverFiltersTopic;

  final Dio _dio;
  final FeedSource _kind;
  final FeedUrlBuilder _urlBuilder;
  final bool _serverFiltersTopic;

  /// Cap on the per-item content cache so it can't grow unbounded.
  static const int _maxCachedBodies = 300;

  /// Max length of the plain-text card snippet built from a description.
  static const int _snippetMaxLength = 400;

  /// content:encoded HTML by article id, filled at parse time so fullBody can
  /// return the complete article without a second network fetch. Cleared once it
  /// grows past a few refreshes so it can't leak memory.
  final Map<String, String> _fullHtmlById = {};

  @override
  FeedSource get kind => _kind;

  @override
  Future<List<Article>> topPosts(
    String topic, {
    int limit = AppConfig.feedLimit,
    int page = 1,
    FeedSort sort = FeedSort.newest,
  }) async {
    if (page > 1) return const []; // RSS feeds are a single page.
    final items = await _load(_urlBuilder(topic, sort));
    if (_serverFiltersTopic) return items.take(limit).toList();
    return filterArticlesByTopic(items, topic).take(limit).toList();
  }

  @override
  Future<List<Article>> search(
    String query, {
    int limit = AppConfig.searchLimit,
  }) async {
    final items = await _load(_urlBuilder(query, FeedSort.newest));
    if (_serverFiltersTopic) return items.take(limit).toList();
    return filterArticlesByTopic(items, query).take(limit).toList();
  }

  @override
  Future<String> fullBody(Article article) async {
    final cached = _fullHtmlById[article.id];
    if (cached != null && cached.isNotEmpty) {
      final extracted = HtmlReadable.extract(cached);
      if (extracted.isNotEmpty) return extracted;
    }
    final extracted = await fetchReadablePage(_dio, article.url);
    return extracted.isNotEmpty ? extracted : article.body;
  }

  Future<List<Article>> _load(String url) async {
    final resp = await _dio.getUri<String>(
      Uri.parse(url),
      options: Options(
        responseType: ResponseType.plain,
        headers: {'User-Agent': AppConfig.readerUserAgent},
        validateStatus: (status) => status != null && status >= 200 && status < 400,
      ),
    );
    if (_fullHtmlById.length > _maxCachedBodies) _fullHtmlById.clear();
    return parseFeed(resp.data ?? '', kind: _kind, contentSink: _fullHtmlById);
  }

  /// Parses an RSS 2.0 document into articles. When [contentSink] is given, each
  /// item's full content:encoded HTML is stored under the article id for later
  /// use by fullBody. Static + side-effect-free (besides the sink) so it is unit
  /// testable without a Dio instance.
  static List<Article> parseFeed(
    String xmlString, {
    required FeedSource kind,
    Map<String, String>? contentSink,
  }) {
    if (xmlString.trim().isEmpty) return const [];
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(xmlString);
    } on XmlException {
      return const [];
    }
    final articles = <Article>[];
    for (final item in doc.findAllElements('item')) {
      final article = _toArticle(item, kind);
      if (article == null) continue;
      if (contentSink != null) {
        final content = _childText(item, 'encoded');
        if (content.isNotEmpty) contentSink[article.id] = content;
      }
      articles.add(article);
    }
    return articles;
  }

  static Article? _toArticle(XmlElement item, FeedSource kind) {
    final link = _childText(item, 'link');
    final guid = _childText(item, 'guid');
    final rawId = (guid.isNotEmpty ? guid : link).trim();
    final title = _childText(item, 'title');
    if (rawId.isEmpty || title.isEmpty) return null;
    final description = _childText(item, 'description');
    final content = _childText(item, 'encoded');
    final author = _firstNonEmpty([
      _childText(item, 'creator'),
      _childText(item, 'author'),
    ]);
    return Article(
      id: '${kind.id}-$rawId',
      title: title,
      body: _plainSnippet(description.isNotEmpty ? description : content),
      url: link,
      commentsUrl: link,
      author: author,
      topic: '',
      source: kind.label,
      score: 0,
      commentCount: 0,
      publishedAt:
          _parseDate(_childText(item, 'pubDate')) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      imageUrl: _imageFrom(item, content.isNotEmpty ? content : description),
    );
  }

  /// First direct child of [item] whose local name matches [localName], decoded
  /// (entities + CDATA resolved). Matching by local name ignores the namespace
  /// prefix, so `content:encoded` and `dc:creator` resolve to `encoded`/`creator`.
  static String _childText(XmlElement item, String localName) {
    for (final element in item.childElements) {
      if (element.name.local == localName) return element.innerText.trim();
    }
    return '';
  }

  static String _firstNonEmpty(List<String> values) =>
      values.firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');

  /// Strips HTML/markup to a short plain-text snippet for the feed card.
  static String _plainSnippet(String raw) {
    if (raw.trim().isEmpty) return '';
    final text = html_parser.parseFragment(raw).text ?? '';
    final collapsed = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= _snippetMaxLength) return collapsed;
    return '${collapsed.substring(0, _snippetMaxLength).trimRight()}…';
  }

  static String _imageFrom(XmlElement item, String contentHtml) {
    for (final element in item.childElements) {
      final local = element.name.local;
      if (local == 'enclosure' || local == 'content' || local == 'thumbnail') {
        final url = element.getAttribute('url') ?? '';
        final type = element.getAttribute('type') ?? '';
        if (url.startsWith('http') &&
            (type.startsWith('image') || _looksImage(url))) {
          return url;
        }
      }
    }
    final match = RegExp(
      r'<img[^>]+src="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(contentHtml);
    final src = match?.group(1) ?? '';
    return src.startsWith('http') ? src : '';
  }

  static bool _looksImage(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp') ||
        lower.contains('.gif');
  }

  /// Parses an ISO-8601 (Atom) or RFC-822 (RSS `pubDate`) date to UTC.
  static DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso.toUtc();
    final match = RegExp(
      r'(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{4}|[A-Za-z]{1,4})?',
    ).firstMatch(raw);
    if (match == null) return null;
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final month = months[match.group(2)!.toLowerCase()];
    if (month == null) return null;
    var dateTime = DateTime.utc(
      int.parse(match.group(3)!),
      month,
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.tryParse(match.group(6) ?? '') ?? 0,
    );
    final zone = match.group(7);
    if (zone != null && (zone.startsWith('+') || zone.startsWith('-'))) {
      final sign = zone.startsWith('-') ? -1 : 1;
      final offset = Duration(
        hours: sign * int.parse(zone.substring(1, 3)),
        minutes: sign * int.parse(zone.substring(3, 5)),
      );
      dateTime = dateTime.subtract(offset);
    }
    return dateTime;
  }
}
