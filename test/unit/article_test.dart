import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/models/article.dart';

void main() {
  test('tolerates missing fields', () {
    final a = Article.fromJson(const {});
    expect(a.id, '');
    expect(a.score, 0);
    expect(a.hasImage, false);
  });

  test('hasImage requires an http url', () {
    expect(Article.fromJson(const {'imageUrl': 'self'}).hasImage, false);
    expect(
        Article.fromJson(const {'imageUrl': 'https://x/y.jpg'}).hasImage, true);
  });

  test('link prefers url then falls back to comments', () {
    expect(
        Article.fromJson(const {'url': 'https://a', 'commentsUrl': 'https://b'})
            .link,
        'https://a');
    expect(Article.fromJson(const {'commentsUrl': 'https://b'}).link,
        'https://b');
  });

  test('round-trips through json', () {
    final a = Article.fromJson(const {
      'id': 'hn-1',
      'title': 'T',
      'score': 5,
      'publishedAt': 1700000000000,
    });
    final back = Article.fromJson(a.toJson());
    expect(back.id, 'hn-1');
    expect(back.score, 5);
    expect(back.publishedAt, a.publishedAt);
  });
}
