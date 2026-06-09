import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feed/application/feed_providers.dart';
import '../../feed/data/models/reddit_post.dart';

/// Current search term. The screen debounces input before updating this so we
/// don't fire a request on every keystroke.
final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
  void clear() => state = '';
}

/// Results for the current [searchQueryProvider]; empty query yields no work.
final searchResultsProvider =
    FutureProvider.autoDispose<List<RedditPost>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) return const [];
  final repo = ref.watch(redditRepositoryProvider);
  final page = await repo.search(query: query);
  return page.posts;
});
