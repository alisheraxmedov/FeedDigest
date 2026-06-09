import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/features/feed/data/models/reddit_page.dart';
import 'package:feeddigest/features/feed/data/models/reddit_post.dart';

void main() {
  group('RedditPost.fromJson', () {
    test('maps core fields and decodes HTML entities', () {
      final post = RedditPost.fromJson({
        'id': 'abc',
        'title': 'Tom &amp; Jerry',
        'selftext': 'a &lt;b&gt;',
        'author': 'alice',
        'subreddit': 'FlutterDev',
        'permalink': '/r/FlutterDev/comments/abc/',
        'url': 'https://example.com',
        'score': 1234,
        'num_comments': 56,
        'created_utc': 1700000000,
        'is_self': true,
      });

      expect(post.id, 'abc');
      expect(post.title, 'Tom & Jerry');
      expect(post.selftext, 'a <b>');
      expect(post.author, 'alice');
      expect(post.score, 1234);
      expect(post.numComments, 56);
      expect(post.isSelf, isTrue);
      expect(post.fullPermalink,
          'https://www.reddit.com/r/FlutterDev/comments/abc/');
    });

    test('extracts the preview source image and unescapes it', () {
      final post = RedditPost.fromJson({
        'id': 'img1',
        'title': 'pic',
        'preview': {
          'images': [
            {
              'source': {'url': 'https://i.redd.it/x.jpg?a=1&amp;b=2'}
            }
          ]
        },
      });
      expect(post.hasImage, isTrue);
      expect(post.imageUrl, 'https://i.redd.it/x.jpg?a=1&b=2');
    });

    test('falls back to a direct image url', () {
      final post = RedditPost.fromJson({
        'id': 'img2',
        'title': 'pic',
        'url': 'https://i.imgur.com/abc.png',
      });
      expect(post.imageUrl, 'https://i.imgur.com/abc.png');
    });

    test('ignores placeholder thumbnails', () {
      final post = RedditPost.fromJson({
        'id': 'x',
        'title': 't',
        'thumbnail': 'self',
      });
      expect(post.thumbnailUrl, '');
      expect(post.hasImage, isFalse);
    });

    test('equality is by id', () {
      final a = RedditPost.fromJson({'id': '1', 'title': 'a'});
      final b = RedditPost.fromJson({'id': '1', 'title': 'different'});
      expect(a, equals(b));
    });
  });

  group('RedditPage.fromListing', () {
    test('parses children and the after cursor, skipping stickied', () {
      final page = RedditPage.fromListing({
        'data': {
          'after': 't3_next',
          'children': [
            {
              'kind': 't3',
              'data': {'id': '1', 'title': 'first'}
            },
            {
              'kind': 't3',
              'data': {'id': '2', 'title': 'pinned', 'stickied': true}
            },
          ],
        }
      });
      expect(page.posts.length, 1);
      expect(page.posts.first.title, 'first');
      expect(page.after, 't3_next');
      expect(page.hasMore, isTrue);
    });

    test('handles malformed input gracefully', () {
      final page = RedditPage.fromListing({'data': 'oops'});
      expect(page.posts, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });
}
