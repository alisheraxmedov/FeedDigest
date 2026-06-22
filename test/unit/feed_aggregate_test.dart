import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/core/sources/article_source.dart';
import 'package:feeddigest/features/feed/viewmodel/feed_viewmodel.dart';
import 'package:feeddigest/models/article.dart';

Article _a(String id, {int score = 0, int publishedMs = 0}) =>
    Article.fromJson({'id': id, 'score': score, 'publishedAt': publishedMs});

void main() {
  test('aggregate dedups by id and sorts by score when popular', () {
    final result = FeedViewModel.aggregate([
      [_a('a', score: 10), _a('b', score: 50)],
      [_a('b', score: 50), _a('c', score: 30)],
    ], FeedSort.popular);
    expect(result.map((a) => a.id).toList(), ['b', 'c', 'a']);
  });

  test('aggregate dedups by id and sorts by date when newest', () {
    final result = FeedViewModel.aggregate([
      [_a('old', publishedMs: 1000), _a('new', publishedMs: 5000)],
      [_a('new', publishedMs: 5000), _a('mid', publishedMs: 3000)],
    ], FeedSort.newest);
    expect(result.map((a) => a.id).toList(), ['new', 'mid', 'old']);
  });

  test('aggregate handles empty input', () {
    expect(FeedViewModel.aggregate(const [], FeedSort.newest), isEmpty);
  });
}
