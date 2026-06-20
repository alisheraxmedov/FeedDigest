import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/sources/article_source.dart';

final feedSourceProvider =
    NotifierProvider<FeedSourceController, FeedSource>(FeedSourceController.new);

class FeedSourceController extends Notifier<FeedSource> {
  static const String _key = 'feed_source';

  @override
  FeedSource build() =>
      FeedSource.fromId(ref.read(metaBoxProvider).get(_key) as String?);

  void select(FeedSource source) {
    ref.read(metaBoxProvider).put(_key, source.id);
    state = source;
  }
}

final activeSourceProvider = Provider<ArticleSource>((ref) {
  return switch (ref.watch(feedSourceProvider)) {
    FeedSource.hackerNews => ref.watch(hackerNewsSourceProvider),
    FeedSource.devto => ref.watch(devtoSourceProvider),
  };
});

final feedSortProvider =
    NotifierProvider<FeedSortController, FeedSort>(FeedSortController.new);

class FeedSortController extends Notifier<FeedSort> {
  static const String _key = 'feed_sort';

  @override
  FeedSort build() =>
      FeedSort.fromId(ref.read(metaBoxProvider).get(_key) as String?);

  void select(FeedSort sort) {
    ref.read(metaBoxProvider).put(_key, sort.id);
    state = sort;
  }
}
