import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/features/feed/data/models/reddit_comment.dart';

void main() {
  group('RedditComment.fromThread', () {
    final thread = [
      {
        'data': {
          'children': [
            {
              'kind': 't3',
              'data': {'id': 'post'}
            }
          ]
        }
      },
      {
        'data': {
          'children': [
            {
              'kind': 't1',
              'data': {
                'id': 'c1',
                'author': 'low',
                'body': 'low score',
                'score': 5,
                'created_utc': 1700000000,
              }
            },
            {
              'kind': 't1',
              'data': {
                'id': 'c2',
                'author': 'high',
                'body': 'high score',
                'score': 99,
                'created_utc': 1700000000,
                'is_submitter': true,
              }
            },
            {
              'kind': 't1',
              'data': {
                'id': 'c3',
                'author': 'x',
                'body': '[removed]',
                'score': 50,
              }
            },
            {'kind': 'more', 'data': {}},
          ]
        }
      }
    ];

    test('sorts by score, drops removed bodies and "more" stubs', () {
      final comments = RedditComment.fromThread(thread);
      expect(comments.length, 2);
      expect(comments.first.author, 'high'); // highest score first
      expect(comments.first.isSubmitter, isTrue);
      expect(comments.any((c) => c.body == '[removed]'), isFalse);
    });

    test('respects the limit', () {
      final comments = RedditComment.fromThread(thread, limit: 1);
      expect(comments.length, 1);
      expect(comments.first.author, 'high');
    });

    test('returns empty on malformed input', () {
      expect(RedditComment.fromThread('nope'), isEmpty);
      expect(RedditComment.fromThread([]), isEmpty);
    });
  });
}
