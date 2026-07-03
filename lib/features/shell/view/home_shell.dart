/*
HomeShell hosts the four primary tabs behind a frosted bottom navigation bar
(iPhone-style blur with a 1px top border). The active tab shows a hugeicons line
icon inside an accent-tinted pill with a bolder label; the body extends behind
the bar so feed content scrolls under the blur.
*/
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../favorites/view/favorites_screen.dart';
import '../../feed/view/feed_screen.dart';
import '../../search/view/search_screen.dart';
import '../../settings/view/settings_screen.dart';
import '../viewmodel/home_tab_viewmodel.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _screens = [
    FeedScreen(),
    SearchScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabProvider);
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: index, children: _screens),
      bottomNavigationBar: _FrostedNav(
        index: index,
        onTap: (i) => ref.read(homeTabProvider.notifier).select(i),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final List<List<dynamic>> icon;
  final String label;
}

class _FrostedNav extends StatelessWidget {
  const _FrostedNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final items = <_NavItem>[
      _NavItem(HugeIcons.strokeRoundedHome01, l.navFeed),
      _NavItem(HugeIcons.strokeRoundedSearch01, l.navSearch),
      _NavItem(HugeIcons.strokeRoundedBookmark01, l.navSaved),
      _NavItem(HugeIcons.strokeRoundedSettings01, l.navSettings),
    ];
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: palette.navBar,
            border: Border(top: BorderSide(color: palette.mutedBorder)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < items.length; i++)
                    _NavButton(
                      item: items[i],
                      active: i == index,
                      onTap: () => onTap(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = active ? palette.accentText : palette.textDim;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: active ? palette.accentSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: HugeIcon(
                  icon: item.icon,
                  size: 24,
                  color: color,
                  strokeWidth: active ? 2.2 : 1.7,
                ),
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
