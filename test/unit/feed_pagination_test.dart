import 'package:feeddigest/core/config/app_config.dart';
import 'package:feeddigest/core/sources/article_source.dart';
import 'package:feeddigest/features/feed/viewmodel/feed_viewmodel.dart';
import 'package:feeddigest/models/article.dart';
import 'package:flutter_test/flutter_test.dart';

Article _a(String id) => Article(
  id: id,
  title: 't$id',
  body: '',
  url: '',
  commentsUrl: '',
  author: '',
  topic: 'x',
  source: 's',
  score: 0,
  commentCount: 0,
  publishedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  imageUrl: '',
);

void main() {
  group('FeedViewModel.pageFromRaw', () {
    test(
      'full probe (feedLimit + 1) -> hasNext, items trimmed to feedLimit',
      () {
        final raw = [for (var i = 0; i <= AppConfig.feedLimit; i++) _a('$i')];
        final page = FeedViewModel.pageFromRaw(raw, 2, FeedSort.newest);
        expect(page.items.length, AppConfig.feedLimit);
        expect(page.hasNext, isTrue);
        expect(page.page, 2);
      },
    );

    test('exactly feedLimit -> hasNext false (no empty last-page trap)', () {
      final raw = [for (var i = 0; i < AppConfig.feedLimit; i++) _a('$i')];
      final page = FeedViewModel.pageFromRaw(raw, 1, FeedSort.newest);
      expect(page.hasNext, isFalse);
      expect(page.items.length, AppConfig.feedLimit);
    });

    test('short page -> hasNext false, all items kept', () {
      final raw = [for (var i = 0; i < 3; i++) _a('$i')];
      final page = FeedViewModel.pageFromRaw(raw, 1, FeedSort.newest);
      expect(page.hasNext, isFalse);
      expect(page.items.length, 3);
    });
  });
}
