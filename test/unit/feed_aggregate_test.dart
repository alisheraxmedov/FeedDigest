import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/features/feed/viewmodel/feed_viewmodel.dart';
import 'package:feeddigest/models/reddit_post.dart';

RedditPost _p(String id, int score) =>
    RedditPost.fromJson({'id': id, 'score': score});

void main() {
  test('aggregate dedups by id and sorts by score desc', () {
    final result = FeedViewModel.aggregate([
      [_p('a', 10), _p('b', 50)],
      [_p('b', 50), _p('c', 30)],
    ]);
    expect(result.map((p) => p.id).toList(), ['b', 'c', 'a']);
  });

  test('aggregate handles empty input', () {
    expect(FeedViewModel.aggregate(const []), isEmpty);
  });
}
