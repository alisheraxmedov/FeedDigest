/*
HtmlReadable — a tiny readability extractor.
Given a raw web page, it strips boilerplate (scripts, nav, footers) and returns
the main article text as simple <p>-wrapped HTML. Used for sources whose API
carries no article body (e.g. Hacker News link posts): the linked page is
fetched and reduced to readable text for the detail view and AI summary.
Returns '' when nothing meaningful is found so callers can fall back cleanly.
*/
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

class HtmlReadable {
  HtmlReadable._();

  /// Cap so a huge page can't bloat memory, the renderer, or the AI prompt.
  static const int _maxChars = 8000;

  /// Boilerplate containers removed before extracting text.
  static const List<String> _dropTags = [
    'script',
    'style',
    'noscript',
    'template',
    'nav',
    'header',
    'footer',
    'aside',
    'form',
    'svg',
    'iframe',
    'button',
    'figure',
  ];

  /// Block elements whose text makes up the readable body, in document order.
  static const String _blockSelector = 'p, h1, h2, h3, h4, li, blockquote, pre';

  /// Extracts the readable body of [rawHtml] as `<p>`-wrapped HTML.
  static String extract(String rawHtml) {
    if (rawHtml.trim().isEmpty) return '';
    final Document doc;
    try {
      doc = html_parser.parse(rawHtml);
    } catch (_) {
      return '';
    }
    final root =
        doc.querySelector('article') ?? doc.querySelector('main') ?? doc.body;
    if (root == null) return '';

    for (final tag in _dropTags) {
      for (final el in root.querySelectorAll(tag)) {
        el.remove();
      }
    }

    final seen = <String>{};
    final blocks = <String>[];
    var length = 0;
    for (final el in root.querySelectorAll(_blockSelector)) {
      final text = _collapse(el.text);
      // Skip empties, near-empties, and nested duplicates (e.g. a <p> inside
      // an <li> already captured).
      if (text.length < 2 || !seen.add(text)) continue;
      blocks.add(text);
      length += text.length;
      if (length >= _maxChars) break;
    }

    if (blocks.isEmpty) {
      final whole = _collapse(root.text);
      if (whole.isEmpty) return '';
      return '<p>${_escape(_truncate(whole))}</p>';
    }
    return blocks.map((b) => '<p>${_escape(_truncate(b))}</p>').join();
  }

  static String _collapse(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _truncate(String s) =>
      s.length <= _maxChars ? s : s.substring(0, _maxChars);

  static String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
