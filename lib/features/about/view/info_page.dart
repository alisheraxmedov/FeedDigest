/*
In-app content pages reached from the home drawer: About, Privacy Policy, Terms
of Service and Support. About shows the app identity, version and a short
description; the legal/support pages currently show a themed "coming soon"
placeholder (content is filled in later). All read their colours from AppPalette
so they match both the dark and light themes.
*/
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../l10n/app_localizations.dart';

/// App version shown on the About page. Kept in step with `pubspec.yaml`.
const String kAppVersion = '1.0.0';

/// A simple scrollable content page with a titled app bar. Callers pass an
/// already-localized [title] and the body [child].
class InfoPage extends StatelessWidget {
  const InfoPage({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: child,
        ),
      ),
    );
  }
}

void openAbout(BuildContext context) {
  final l = AppLocalizations.of(context);
  _push(context, l.about, const _AboutBody());
}

void openPrivacyPolicy(BuildContext context) {
  final l = AppLocalizations.of(context);
  _push(context, l.privacyPolicy, const _ComingSoonBody(icon: Icons.privacy_tip_outlined));
}

void openTermsOfService(BuildContext context) {
  final l = AppLocalizations.of(context);
  _push(context, l.termsOfService, const _ComingSoonBody(icon: Icons.description_outlined));
}

void openSupport(BuildContext context) {
  final l = AppLocalizations.of(context);
  _push(context, l.support, const _ComingSoonBody(icon: Icons.support_agent_outlined));
}

void _push(BuildContext context, String title, Widget body) {
  unawaited(
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InfoPage(title: title, child: body),
      ),
    ),
  );
}

class _AboutBody extends StatelessWidget {
  const _AboutBody();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 28),
        const IconCircle(icon: Icons.hub, accent: true, size: 96),
        const SizedBox(height: 20),
        Text(
          l.appTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.version(kAppVersion),
          style: TextStyle(fontSize: 14, color: palette.textDim),
        ),
        const SizedBox(height: 24),
        NeonCard(
          padding: const EdgeInsets.all(20),
          child: Text(
            l.aboutDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _ComingSoonBody extends StatelessWidget {
  const _ComingSoonBody({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 96),
      child: Column(
        children: [
          IconCircle(icon: icon, accent: true, size: 80),
          const SizedBox(height: 22),
          Text(
            l.comingSoon,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.sectionComingSoon,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5, color: palette.textDim),
          ),
        ],
      ),
    );
  }
}
