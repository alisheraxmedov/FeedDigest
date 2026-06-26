import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/article.dart';
import '../../feed/viewmodel/feed_source_viewmodel.dart';

final searchViewModelProvider =
    AsyncNotifierProvider<SearchViewModel, List<Article>>(SearchViewModel.new);

class SearchViewModel extends AsyncNotifier<List<Article>> {
  /// Monotonic token so a slow earlier query cannot overwrite a newer result.
  int _requestId = 0;

  @override
  Future<List<Article>> build() async => const [];

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _requestId++;
      state = const AsyncData([]);
      return;
    }
    final requestId = ++_requestId;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(activeSourceProvider).search(trimmed),
    );
    if (requestId != _requestId) return; // superseded by a newer search
    state = result;
  }

  void clear() {
    _requestId++;
    state = const AsyncData([]);
  }
}
