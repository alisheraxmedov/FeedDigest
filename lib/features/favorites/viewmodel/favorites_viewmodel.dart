import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../models/article.dart';

final favoritesViewModelProvider =
    NotifierProvider<FavoritesViewModel, List<Article>>(FavoritesViewModel.new);

class FavoritesViewModel extends Notifier<List<Article>> {
  @override
  List<Article> build() => ref.watch(favoritesRepositoryProvider).all();

  Future<void> toggle(Article article) async {
    await ref.read(favoritesRepositoryProvider).toggle(article);
    state = ref.read(favoritesRepositoryProvider).all();
  }

  Future<void> remove(String id) async {
    await ref.read(favoritesRepositoryProvider).remove(id);
    state = ref.read(favoritesRepositoryProvider).all();
  }
}
