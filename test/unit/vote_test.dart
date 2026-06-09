import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/features/feed/application/vote_providers.dart';
import 'package:feeddigest/features/feed/data/models/reddit_post.dart';

RedditPost _post({int score = 100, bool? likes}) => RedditPost(
      id: 'abc',
      title: 't',
      selftext: '',
      author: 'a',
      subreddit: 's',
      permalink: '/p',
      url: '',
      imageUrl: '',
      thumbnailUrl: '',
      score: score,
      numComments: 0,
      createdUtc: 0,
      domain: '',
      isSelf: true,
      isVideo: false,
      over18: false,
      likes: likes,
    );

void main() {
  group('RedditPost vote helpers', () {
    test('fullname is t3_<id>', () {
      expect(_post().fullname, 't3_abc');
    });

    test('voteDirection reflects likes', () {
      expect(_post(likes: null).voteDirection, 0);
      expect(_post(likes: true).voteDirection, 1);
      expect(_post(likes: false).voteDirection, -1);
    });
  });

  group('voteViewFor', () {
    test('no override uses the post value', () {
      final v = voteViewFor(_post(score: 100, likes: true), const {});
      expect(v.direction, 1);
      expect(v.score, 100);
    });

    test('upvoting an un-voted post adds one', () {
      final v = voteViewFor(_post(score: 100, likes: null), const {'abc': 1});
      expect(v.direction, 1);
      expect(v.score, 101);
    });

    test('switching down→up swings the score by two', () {
      final v = voteViewFor(_post(score: 100, likes: false), const {'abc': 1});
      // base 100 already reflects the downvote; up = +2 relative to that.
      expect(v.score, 102);
      expect(v.isUp, isTrue);
    });

    test('clearing an upvote removes one', () {
      final v = voteViewFor(_post(score: 100, likes: true), const {'abc': 0});
      expect(v.direction, 0);
      expect(v.score, 99);
    });
  });
}
