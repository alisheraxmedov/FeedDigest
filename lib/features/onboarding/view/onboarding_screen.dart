/*
First-run onboarding (design handoff screen 01). A centered intro — app icon,
wordmark, tagline and three feature rows — over a gradient "Get started" button
plus a hint pointing to the Gemini key in Settings. Shown once; both actions mark
onboarding seen. No feature logic lives here.
*/
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../interests/view/interests_screen.dart';
import '../../settings/view/settings_screen.dart';
import '../viewmodel/onboarding_viewmodel.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;

    void finish() {
      final navigator = Navigator.of(context);
      unawaited(ref.read(onboardingSeenProvider.notifier).markSeen());
      navigator.pop();
      // First run continues into the interests picker; returning users (already
      // seeded) just land on the home shell.
      if (!ref.read(subscriptionRepositoryProvider).isSeeded) {
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const InterestsScreen(),
            fullscreenDialog: true,
          ),
        );
      }
    }

    void openSettings() {
      final navigator = Navigator.of(context);
      unawaited(ref.read(onboardingSeenProvider.notifier).markSeen());
      navigator.pop();
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -1.15),
              radius: 1.1,
              colors: [palette.bgGlow, Colors.transparent],
              stops: const [0, 0.6],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.accent.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 50,
                                    spreadRadius: -12,
                                    offset: const Offset(0, 24),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/icons/feeddigest-1b-monogram-f.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 26),
                            const Wordmark(fontSize: 33),
                            const SizedBox(height: 13),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 280),
                              child: Text(
                                l.onboardingTagline,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  height: 1.55,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            _Feature(
                              icon: Icons.auto_awesome,
                              title: l.onboardingFeatureAiTitle,
                              subtitle: l.onboardingFeatureAiSub,
                            ),
                            const SizedBox(height: 11),
                            _Feature(
                              icon: Icons.rss_feed,
                              title: l.onboardingFeatureSourcesTitle,
                              subtitle: l.onboardingFeatureSourcesSub,
                            ),
                            const SizedBox(height: 11),
                            _Feature(
                              icon: Icons.bookmark_border,
                              title: l.onboardingFeatureSaveTitle,
                              subtitle: l.onboardingFeatureSaveSub,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    child: Column(
                      children: [
                        NeonButton(
                          label: l.onboardingGetStarted,
                          onPressed: finish,
                          height: 52,
                          radius: 15,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.onboardingKeyHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: palette.textDim,
                          ),
                        ),
                        TextButton(
                          onPressed: openSettings,
                          child: Text(
                            l.onboardingOpenSettings,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: palette.accentText,
                            ),
                          ),
                        ),
                      ],
                    ),
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

/// One onboarding feature row: an accentSoft icon tile + title + subtitle.
class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconCircle(icon: icon, accent: true, size: 42, radius: 13),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12.5, color: palette.textDim),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
