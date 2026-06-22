import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/sources/article_source.dart';
import '../../../models/article.dart';
import '../../subscriptions/viewmodel/subscriptions_viewmodel.dart';
import 'feed_source_viewmodel.dart';

final selectedTopicProvider =
    NotifierProvider<SelectedTopic, String?>(SelectedTopic.new);

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

final feedViewModelProvider =
    AsyncNotifierProvider<FeedViewModel, List<Article>>(FeedViewModel.new);

class FeedViewModel extends AsyncNotifier<List<Article>> {
  @override
  Future<List<Article>> build() async {
    final source = ref.watch(activeSourceProvider);
    final subs = ref.watch(subscriptionsViewModelProvider);
    final selected = ref.watch(selectedTopicProvider);
    final sort = ref.watch(feedSortProvider);
    if (subs.isEmpty) return const [];
    if (selected != null) {
      return sortArticles(await source.topPosts(selected, sort: sort), sort);
    }

    final topics = subs.map((s) => s.topic).toList();
    final lists = <List<Article>>[];
    for (var i = 0; i < topics.length; i += AppConfig.fetchConcurrency) {
      final chunk = topics.skip(i).take(AppConfig.fetchConcurrency);
      final results = await Future.wait(
        chunk.map((topic) => source.topPosts(topic, sort: sort).catchError(
              (_) => <Article>[],
            )),
      );
      lists.addAll(results);
    }
    return aggregate(lists, sort);
  }

  Future<void> refresh() {
    ref.invalidateSelf();
    return future;
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
