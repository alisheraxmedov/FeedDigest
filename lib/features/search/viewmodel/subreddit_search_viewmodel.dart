import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../models/subreddit.dart';

final subredditSearchViewModelProvider =
    AsyncNotifierProvider<SubredditSearchViewModel, List<Subreddit>>(
        SubredditSearchViewModel.new);

class SubredditSearchViewModel extends AsyncNotifier<List<Subreddit>> {
  @override
  Future<List<Subreddit>> build() async => const [];

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(redditRepositoryProvider).searchSubreddits(trimmed));
  }

  void clear() => state = const AsyncData([]);
}
