import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../models/reddit_post.dart';

final favoritesViewModelProvider =
    NotifierProvider<FavoritesViewModel, List<RedditPost>>(
        FavoritesViewModel.new);

class FavoritesViewModel extends Notifier<List<RedditPost>> {
  @override
  List<RedditPost> build() => ref.watch(favoritesRepositoryProvider).all();

  bool isFavorite(String id) =>
      ref.read(favoritesRepositoryProvider).contains(id);

  Future<void> toggle(RedditPost post) async {
    await ref.read(favoritesRepositoryProvider).toggle(post);
    state = ref.read(favoritesRepositoryProvider).all();
  }

  Future<void> remove(String id) async {
    await ref.read(favoritesRepositoryProvider).remove(id);
    state = ref.read(favoritesRepositoryProvider).all();
  }
}
