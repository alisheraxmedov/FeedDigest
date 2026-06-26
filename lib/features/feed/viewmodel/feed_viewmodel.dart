import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/sources/article_source.dart';
import '../../../models/article.dart';
import '../../subscriptions/viewmodel/subscriptions_viewmodel.dart';
import 'feed_source_viewmodel.dart';

final selectedTopicProvider = NotifierProvider<SelectedTopic, String?>(
  SelectedTopic.new,
);

class SelectedTopic extends Notifier<String?> {
  @override
  String? build() {
    final subs = ref.watch(subscriptionsViewModelProvider);
    final current = stateOrNull;
    if (current != null && subs.any((s) => s.topic == current)) {
      return current;
    }
    return null;
  }

  void select(String? topic) => state = topic;
}

/// One page of the feed plus whether a further page is likely available.
class FeedPage {
  const FeedPage({
    required this.items,
    required this.page,
    required this.hasNext,
  });

  final List<Article> items;
  final int page;
  final bool hasNext;
}

/// Current 1-indexed feed page. Resets to 1 whenever the underlying query
/// (topic, sort, source or subscriptions) changes.
final feedPageProvider = NotifierProvider<FeedPageController, int>(
  FeedPageController.new,
);

class FeedPageController extends Notifier<int> {
  @override
  int build() {
    ref.watch(selectedTopicProvider);
    ref.watch(feedSortProvider);
    ref.watch(activeSourceProvider);
    ref.watch(subscriptionsViewModelProvider);
    return 1;
  }

  void set(int page) {
    if (page >= 1 && page != state) state = page;
  }

  void next() => state = state + 1;

  void prev() {
    if (state > 1) state = state - 1;
  }
}

final feedViewModelProvider = AsyncNotifierProvider<FeedViewModel, FeedPage>(
  FeedViewModel.new,
);

class FeedViewModel extends AsyncNotifier<FeedPage> {
  @override
  Future<FeedPage> build() async {
    final source = ref.watch(activeSourceProvider);
    final subs = ref.watch(subscriptionsViewModelProvider);
    final selected = ref.watch(selectedTopicProvider);
    final sort = ref.watch(feedSortProvider);
    final page = ref.watch(feedPageProvider);
    if (subs.isEmpty) {
      return const FeedPage(items: [], page: 1, hasNext: false);
    }

    // Fetch one extra item as a probe: a next page exists only if that probe
    // came back, which guarantees page+1 is non-empty (no dead-end trap).
    const probe = AppConfig.feedLimit + 1;

    if (selected != null) {
      final raw = await source.topPosts(
        selected,
        limit: probe,
        page: page,
        sort: sort,
      );
      return pageFromRaw(raw, page, sort);
    }

    final topics = subs.map((s) => s.topic).toList();
    final lists = <List<Article>>[];
    var failures = 0;
    for (var i = 0; i < topics.length; i += AppConfig.fetchConcurrency) {
      final chunk = topics.skip(i).take(AppConfig.fetchConcurrency);
      final results = await Future.wait(
        chunk.map((topic) async {
          try {
            return await source.topPosts(
              topic,
              limit: probe,
              page: page,
              sort: sort,
            );
          } catch (_) {
            failures++;
            return <Article>[];
          }
        }),
      );
      lists.addAll(results);
    }
    // Surface a real error (with retry) when every topic failed, instead of a
    // misleading "nothing found" empty state.
    if (failures == topics.length) {
      throw Exception('feed_unavailable');
    }
    final hasNext = lists.any((l) => l.length > AppConfig.feedLimit);
    final trimmed = lists
        .map((l) => l.take(AppConfig.feedLimit).toList())
        .toList();
    return FeedPage(
      items: aggregate(trimmed, sort),
      page: page,
      hasNext: hasNext,
    );
  }

  Future<void> refresh() {
    ref.invalidateSelf();
    return future;
  }

  /// Splits a probe-sized fetch (feedLimit + 1 items) into the visible page and
  /// whether a further page exists: a next page exists only when the probe item
  /// came back, which guarantees page+1 is non-empty (no dead-end).
  static FeedPage pageFromRaw(List<Article> raw, int page, FeedSort sort) {
    final hasNext = raw.length > AppConfig.feedLimit;
    final items = hasNext ? raw.take(AppConfig.feedLimit).toList() : raw;
    return FeedPage(
      items: sortArticles(items, sort),
      page: page,
      hasNext: hasNext,
    );
  }

  static List<Article> aggregate(List<List<Article>> lists, FeedSort sort) {
    final seen = <String>{};
    final merged = <Article>[];
    for (final list in lists) {
      for (final article in list) {
        if (seen.add(article.id)) merged.add(article);
      }
    }
    return sortArticles(merged, sort);
  }

  static List<Article> sortArticles(List<Article> list, FeedSort sort) {
    final sorted = [...list];
    switch (sort) {
      case FeedSort.newest:
        sorted.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      case FeedSort.popular:
        sorted.sort((a, b) => b.score.compareTo(a.score));
    }
    return sorted;
  }
}
