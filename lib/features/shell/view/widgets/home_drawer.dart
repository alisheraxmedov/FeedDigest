/*
HomeDrawer is the single navigation surface opened from the feed app bar's
hamburger. The "Feed" section hosts the actions that used to live as app-bar
icons — the AI digest, the feed sort and the reading-streak read-out — while the
"More" section links to About, sharing, rating and the legal/support pages. It
reads its colours from AppPalette so it matches both the dark and light themes.
*/
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/sources/article_source.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/neon_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../about/view/info_page.dart';
import '../../../digest/view/digest_sheet.dart';
import '../../../feed/viewmodel/feed_source_viewmodel.dart';
import '../../../feed/viewmodel/streak_viewmodel.dart';

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final streak = ref.watch(streakProvider);
    final sort = ref.watch(feedSortProvider);
    final sortLabel = sort == FeedSort.newest ? l.sortNewest : l.sortPopular;
    return Drawer(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DrawerHeader(),
            Divider(height: 1, color: palette.mutedBorder),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  _SectionLabel(l.navFeed),
                  _DrawerTile(
                    icon: Icons.auto_awesome,
                    title: l.digestTitle,
                    subtitle: l.digestTooltip,
                    accent: true,
                    onTap: () {
                      Navigator.pop(context);
                      showDigestSheet(context);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.sort,
                    title: l.sortLabel,
                    subtitle: sortLabel,
                    accent: true,
                    onTap: () {
                      Navigator.pop(context);
                      _openSortPicker(context, ref, l, sort);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.local_fire_department,
                    title: l.streakTitle,
                    subtitle: streak.current > 0
                        ? l.streakDays(streak.current)
                        : l.streakNone,
                    accent: streak.current > 0,
                  ),
                  Divider(height: 12, color: palette.mutedBorder),
                  _SectionLabel(l.sectionMore),
                  _DrawerTile(
                    icon: Icons.info_outline,
                    title: l.about,
                    onTap: () {
                      Navigator.pop(context);
                      openAbout(context);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.ios_share,
                    title: l.shareApp,
                    onTap: () {
                      Navigator.pop(context);
                      unawaited(
                        SharePlus.instance.share(
                          ShareParams(text: l.shareAppText),
                        ),
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.star_outline,
                    title: l.rateApp,
                    onTap: () {
                      Navigator.pop(context);
                      _comingSoon(context, l);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.privacy_tip_outlined,
                    title: l.privacyPolicy,
                    onTap: () {
                      Navigator.pop(context);
                      openPrivacyPolicy(context);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.description_outlined,
                    title: l.termsOfService,
                    onTap: () {
                      Navigator.pop(context);
                      openTermsOfService(context);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.support_agent_outlined,
                    title: l.support,
                    onTap: () {
                      Navigator.pop(context);
                      openSupport(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSortPicker(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    FeedSort current,
  ) {
    showOptionPicker<FeedSort>(
      context: context,
      title: l.sortLabel,
      selected: current,
      options: [
        PickerOption(
          value: FeedSort.newest,
          label: l.sortNewest,
          icon: Icons.schedule,
        ),
        PickerOption(
          value: FeedSort.popular,
          label: l.sortPopular,
          icon: Icons.local_fire_department,
        ),
      ],
      onSelected: (value) => ref.read(feedSortProvider.notifier).select(value),
    );
  }

  void _comingSoon(BuildContext context, AppLocalizations l) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.comingSoon)));
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconCircle(icon: Icons.hub, accent: true, size: 52),
          const SizedBox(height: 14),
          Text(
            l.appTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.aboutDescription,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: palette.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: palette.textDim,
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: accent ? palette.accent : scheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: TextStyle(fontSize: 12.5, color: palette.textDim),
            ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
