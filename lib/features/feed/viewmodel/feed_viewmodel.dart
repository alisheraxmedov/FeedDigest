import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../models/reddit_post.dart';
import '../../subscriptions/viewmodel/subscriptions_viewmodel.dart';

final selectedSubredditProvider =
    NotifierProvider<SelectedSubreddit, String?>(SelectedSubreddit.new);

class SelectedSubreddit extends Notifier<String?> {
  @override
  String? build() {
    final subs = ref.watch(subscriptionsViewModelProvider);
    final current = stateOrNull;
    if (current != null && subs.any((s) => s.subreddit == current)) {
      return current;
    }
    return null;
  }

  void select(String? subreddit) => state = subreddit;
}

final feedViewModelProvider =
    AsyncNotifierProvider<FeedViewModel, List<RedditPost>>(FeedViewModel.new);

class FeedViewModel extends AsyncNotifier<List<RedditPost>> {
  @override
  Future<List<RedditPost>> build() async {
    final subs = ref.watch(subscriptionsViewModelProvider);
    final selected = ref.watch(selectedSubredditProvider);
    if (subs.isEmpty) return const [];
    final repo = ref.watch(redditRepositoryProvider);
    if (selected != null) return repo.topPosts(selected);

    final names = subs.map((s) => s.subreddit).toList();
    final lists = <List<RedditPost>>[];
    for (var i = 0; i < names.length; i += AppConfig.fetchConcurrency) {
      final chunk = names.skip(i).take(AppConfig.fetchConcurrency);
      final results = await Future.wait(
        chunk.map(
          (name) => repo.topPosts(name).catchError((_) => <RedditPost>[]),
        ),
      );
      lists.addAll(results);
    }
    return aggregate(lists);
  }

  Future<void> refresh() {
    ref.invalidateSelf();
    return future;
  }

  static List<RedditPost> aggregate(List<List<RedditPost>> lists) {
    final seen = <String>{};
    final merged = <RedditPost>[];
    for (final list in lists) {
      for (final post in list) {
        if (seen.add(post.id)) merged.add(post);
      }
    }
    merged.sort((a, b) => b.score.compareTo(a.score));
    return merged;
  }
}
