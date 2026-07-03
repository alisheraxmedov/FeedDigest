import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/sources/article_source.dart';

final feedSourceProvider = NotifierProvider<FeedSourceController, FeedSource>(
  FeedSourceController.new,
);

class FeedSourceController extends Notifier<FeedSource> {
  static const String _key = 'feed_source';

  @override
  FeedSource build() =>
      FeedSource.fromId(ref.read(metaBoxProvider).get(_key) as String?);

  Future<void> select(FeedSource source) async {
    final box = ref.read(metaBoxProvider);
    await box.put(_key, source.id);
    await box.flush();
    state = source;
  }
}

final activeSourceProvider = Provider<ArticleSource>((ref) {
  return switch (ref.watch(feedSourceProvider)) {
    FeedSource.hackerNews => ref.watch(hackerNewsSourceProvider),
    FeedSource.devto => ref.watch(devtoSourceProvider),
    FeedSource.lobsters => ref.watch(lobstersSourceProvider),
    FeedSource.habr => ref.watch(habrSourceProvider),
    FeedSource.vcru => ref.watch(vcruSourceProvider),
  };
});

final feedSortProvider = NotifierProvider<FeedSortController, FeedSort>(
  FeedSortController.new,
);

class FeedSortController extends Notifier<FeedSort> {
  static const String _key = 'feed_sort';

  @override
  FeedSort build() =>
      FeedSort.fromId(ref.read(metaBoxProvider).get(_key) as String?);

  Future<void> select(FeedSort sort) async {
    final box = ref.read(metaBoxProvider);
    await box.put(_key, sort.id);
    await box.flush();
    state = sort;
  }
}
