import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/features/feed/data/models/subreddit.dart';

void main() {
  group('Subreddit.fromListing', () {
    test('parses t5 children and strips icon query strings', () {
      final subs = Subreddit.fromListing({
        'data': {
          'children': [
            {
              'kind': 't5',
              'data': {
                'display_name': 'FlutterDev',
                'title': 'Flutter Development',
                'subscribers': 220000,
                'community_icon':
                    'https://styles.redditmedia.com/icon.png?width=256&amp;s=abc',
              }
            },
            {
              'kind': 't3', // not a subreddit — ignored
              'data': {'display_name': 'nope'}
            },
          ]
        }
      });

      expect(subs.length, 1);
      expect(subs.first.name, 'FlutterDev');
      expect(subs.first.subscribers, 220000);
      expect(subs.first.iconUrl, 'https://styles.redditmedia.com/icon.png');
    });

    test('returns empty on malformed input', () {
      expect(Subreddit.fromListing('nope'), isEmpty);
      expect(Subreddit.fromListing({'data': 'x'}), isEmpty);
    });

    test('equality is by name, case-insensitively', () {
      const a = Subreddit(
          name: 'FlutterDev', title: '', subscribers: 0, iconUrl: '');
      const b = Subreddit(
          name: 'flutterdev', title: 'x', subscribers: 9, iconUrl: 'y');
      expect(a, equals(b));
    });
  });
}
