import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/core/sources/devto_source.dart';
import 'package:feeddigest/core/sources/hacker_news_source.dart';

void main() {
  test('HackerNewsSource.parse maps hits and builds ids and links', () {
    final data = {
      'hits': [
        {
          'objectID': '111',
          'title': 'Flutter is great',
          'url': 'https://example.com/a',
          'author': 'pg',
          'points': 853,
          'num_comments': 713,
          'created_at_i': 1700000000,
        },
        {
          'objectID': '222',
          'title': '',
          'points': 10,
        },
      ]
    };
    final articles = HackerNewsSource.parse(data, 'flutter');
    expect(articles.length, 1);
    final a = articles.first;
    expect(a.id, 'hn-111');
    expect(a.source, 'Hacker News');
    expect(a.topic, 'flutter');
    expect(a.score, 853);
    expect(a.commentCount, 713);
    expect(a.url, 'https://example.com/a');
    expect(a.commentsUrl, 'https://news.ycombinator.com/item?id=111');
  });

  test('HackerNewsSource.parse uses comments url when story has no url', () {
    final data = {
      'hits': [
        {'objectID': '333', 'title': 'Ask HN', 'points': 5}
      ]
    };
    final a = HackerNewsSource.parse(data, 'ask').first;
    expect(a.url, 'https://news.ycombinator.com/item?id=333');
  });

  test('DevtoSource.parse maps articles and ids', () {
    final data = [
      {
        'id': 9,
        'title': 'Dart tips',
        'url': 'https://dev.to/x/dart-tips',
        'description': 'desc',
        'user': {'name': 'Aziz', 'username': 'aziz'},
        'positive_reactions_count': 85,
        'comments_count': 4,
        'published_at': '2024-01-01T12:00:00Z',
        'cover_image': 'https://img/cover.png',
      },
      {'title': 'no id'},
    ];
    final articles = DevtoSource.parse(data, 'dart');
    expect(articles.length, 1);
    final a = articles.first;
    expect(a.id, 'devto-9');
    expect(a.source, 'dev.to');
    expect(a.author, 'Aziz');
    expect(a.score, 85);
    expect(a.imageUrl, 'https://img/cover.png');
    expect(a.publishedAt.isUtc, true);
  });
}
