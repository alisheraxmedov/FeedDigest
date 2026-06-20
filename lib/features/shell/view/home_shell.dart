import 'package:flutter/material.dart';
import '../../favorites/view/favorites_screen.dart';
import '../../feed/view/feed_screen.dart';
import '../../search/view/search_screen.dart';
import '../../settings/view/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    FeedScreen(),
    SearchScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Qidiruv'),
          NavigationDestination(
              icon: Icon(Icons.favorite_border), label: 'Saqlangan'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Sozlama'),
        ],
      ),
    );
  }
}
