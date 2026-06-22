import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/article.dart';
import '../../feed/viewmodel/feed_source_viewmodel.dart';

final searchViewModelProvider =
    AsyncNotifierProvider<SearchViewModel, List<Article>>(SearchViewModel.new);

class SearchViewModel extends AsyncNotifier<List<Article>> {
  @override
  Future<List<Article>> build() async => const [];

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(activeSourceProvider).search(trimmed));
  }

  void clear() => state = const AsyncData([]);
}
