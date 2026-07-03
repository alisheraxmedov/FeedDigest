import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/core/sources/article_source.dart';
import 'package:feeddigest/core/sources/lobsters_source.dart';
import 'package:feeddigest/core/sources/rss_source.dart';
import 'package:feeddigest/core/utils/topic_filter.dart';
import 'package:feeddigest/models/article.dart';

void main() {
  group('LobstersSource.parse', () {
    test('maps stories, builds ids, links and author', () {
      final data = [
        {
          'short_id': 'ryny2c',
          'title': 'Rust to C',
          'url': 'https://github.com/x/crustc',
          'comments_url': 'https://lobste.rs/s/ryny2c/rust_to_c',
          'submitter_user': 'fractal',
          'tags': ['rust', 'compilers'],
          'score': 52,
          'comment_count': 9,
          'created_at': '2026-07-02T18:19:21.000-05:00',
        },
        {'short_id': '', 'title': 'no id'},
        {'short_id': 'zz', 'title': ''},
      ];
      final articles = LobstersSource.parse(data, 'rust');
      expect(articles.length, 1);
      final a = articles.first;
      expect(a.id, 'lobsters-ryny2c');
      expect(a.source, 'Lobsters');
      expect(a.topic, 'rust');
      expect(a.author, 'fractal');
      expect(a.url, 'https://github.com/x/crustc');
      expect(a.commentsUrl, 'https://lobste.rs/s/ryny2c/rust_to_c');
      expect(a.score, 52);
      expect(a.commentCount, 9);
      expect(a.publishedAt.isUtc, true);
    });

    test('reads submitter_user object form and falls back to first tag', () {
      final data = [
        {
          'short_id': 'ab1',
          'title': 'Story',
          'url': 'https://ex.com',
          'submitter_user': {'username': 'alice'},
          'tags': ['ai'],
        },
      ];
      final a = LobstersSource.parse(data, '').first;
      expect(a.author, 'alice');
      expect(a.topic, 'ai');
    });

    test('uses stories array when data is an object', () {
      final data = {
        'stories': [
          {'short_id': 'q9', 'title': 'From search', 'url': 'https://ex.com'},
        ],
      };
      expect(LobstersSource.parse(data, 'q').single.id, 'lobsters-q9');
    });
  });

  group('RssSource.parseFeed', () {
    const feed = '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:content="http://purl.org/rss/1.0/modules/content/">
  <channel>
    <title>Test</title>
    <item>
      <title>Flutter in prod</title>
      <link>https://habr.com/ru/articles/1001/</link>
      <guid>https://habr.com/ru/articles/1001/</guid>
      <description><![CDATA[<p>Short <b>summary</b> here.</p>]]></description>
      <content:encoded><![CDATA[<p>Full body about Flutter.</p><img src="https://img/x.png"/>]]></content:encoded>
      <dc:creator>ivan</dc:creator>
      <pubDate>Wed, 02 Jul 2026 18:19:21 +0300</pubDate>
      <enclosure url="https://img/cover.jpg" type="image/jpeg" length="1000"/>
    </item>
    <item>
      <title></title>
      <link>https://habr.com/ru/articles/1002/</link>
    </item>
  </channel>
</rss>
''';

    test('maps items, skips untitled, strips description to plain snippet', () {
      final articles = RssSource.parseFeed(feed, kind: FeedSource.habr);
      expect(articles.length, 1);
      final a = articles.first;
      expect(a.id, 'habr-https://habr.com/ru/articles/1001/');
      expect(a.source, 'Habr');
      expect(a.title, 'Flutter in prod');
      expect(a.body, 'Short summary here.');
      expect(a.url, 'https://habr.com/ru/articles/1001/');
      expect(a.author, 'ivan');
      expect(a.imageUrl, 'https://img/cover.jpg');
    });

    test('parses RFC-822 pubDate into UTC', () {
      final a = RssSource.parseFeed(feed, kind: FeedSource.habr).first;
      expect(a.publishedAt.isUtc, true);
      // 18:19:21 +0300 == 15:19:21 UTC
      expect(a.publishedAt, DateTime.utc(2026, 7, 2, 15, 19, 21));
    });

    test('fills the content sink with content:encoded HTML', () {
      final sink = <String, String>{};
      final a =
          RssSource.parseFeed(feed, kind: FeedSource.habr, contentSink: sink)
              .first;
      expect(sink[a.id], contains('Full body about Flutter'));
    });

    test('returns empty for blank or malformed xml', () {
      expect(RssSource.parseFeed('', kind: FeedSource.vcru), isEmpty);
      expect(RssSource.parseFeed('<not xml', kind: FeedSource.vcru), isEmpty);
    });
  });

  group('filterArticlesByTopic', () {
    Article make(String title, {String body = ''}) =>
        Article.fromJson({'id': title, 'title': title, 'body': body});

    final items = [
      make('Flutter state management'),
      make('Rust ownership', body: 'the borrow checker'),
      make('General news', body: 'nothing relevant'),
    ];

    test('empty topic keeps everything', () {
      expect(filterArticlesByTopic(items, ''), hasLength(3));
      expect(filterArticlesByTopic(items, '  '), hasLength(3));
    });

    test('matches title or body, case-insensitive', () {
      expect(filterArticlesByTopic(items, 'FLUTTER').single.title,
          'Flutter state management');
      expect(filterArticlesByTopic(items, 'borrow').single.title,
          'Rust ownership');
    });

    test('no match returns empty (no fallback to unrelated items)', () {
      expect(filterArticlesByTopic(items, 'kubernetes'), isEmpty);
    });
  });
}
