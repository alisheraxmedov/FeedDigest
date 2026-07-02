import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/core/utils/html_readable.dart';

void main() {
  test('extracts paragraphs and drops scripts/nav/style', () {
    const html = '''
      <html><head><style>.x{}</style></head>
      <body>
        <nav>Home About Contact</nav>
        <article>
          <h1>Big Title</h1>
          <p>First paragraph of the story.</p>
          <script>evil()</script>
          <p>Second paragraph here.</p>
        </article>
        <footer>copyright</footer>
      </body></html>''';
    final out = HtmlReadable.extract(html);
    expect(out, contains('Big Title'));
    expect(out, contains('First paragraph of the story.'));
    expect(out, contains('Second paragraph here.'));
    expect(out, isNot(contains('evil')));
    expect(out, isNot(contains('Home About Contact')));
    expect(out, isNot(contains('copyright')));
    expect(out, contains('<p>'));
  });

  test('returns empty for empty or textless html', () {
    expect(HtmlReadable.extract(''), '');
    expect(HtmlReadable.extract('   '), '');
    expect(HtmlReadable.extract('<html><body></body></html>'), '');
  });

  test('escapes angle brackets and ampersands in text', () {
    const html = '<body><p>a &amp; b &lt; c</p></body>';
    final out = HtmlReadable.extract(html);
    // Decoded by the parser to `a & b < c`, then re-escaped for safe rendering.
    expect(out, contains('a &amp; b &lt; c'));
  });

  test('falls back to whole-body text when no block tags exist', () {
    const html = '<body><div>Just some loose text in a div</div></body>';
    final out = HtmlReadable.extract(html);
    expect(out, contains('Just some loose text in a div'));
  });

  test('dedupes nested duplicate blocks', () {
    const html = '<body><ul><li><p>Same line</p></li></ul></body>';
    final out = HtmlReadable.extract(html);
    // "Same line" should appear once, not twice (li + nested p).
    expect(RegExp('Same line').allMatches(out).length, 1);
  });
}
