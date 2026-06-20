import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/state_views.dart';
import '../../feed/view/widgets/post_card.dart';
import '../viewmodel/favorites_viewmodel.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Saqlanganlar')),
      body: favorites.isEmpty
          ? const EmptyView(message: "Hali saqlangan post yo'q")
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (_, i) => PostCard(post: favorites[i]),
            ),
    );
  }
}
