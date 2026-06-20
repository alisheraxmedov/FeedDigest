import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../models/reddit_post.dart';

final searchViewModelProvider =
    AsyncNotifierProvider<SearchViewModel, List<RedditPost>>(
        SearchViewModel.new);

class SearchViewModel extends AsyncNotifier<List<RedditPost>> {
  @override
  Future<List<RedditPost>> build() async => const [];

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(redditRepositoryProvider).searchPosts(trimmed));
  }

  void clear() => state = const AsyncData([]);
}
