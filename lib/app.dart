import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/prefs/preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/connectivity_banner.dart';
import 'features/onboarding/view/onboarding_screen.dart';
import 'features/onboarding/viewmodel/onboarding_viewmodel.dart';
import 'features/shell/view/home_shell.dart';
import 'l10n/app_localizations.dart';

class FeedDigestApp extends ConsumerWidget {
  const FeedDigestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'FeedDigest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: lang.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Float the connectivity banner above every route.
      builder: (context, child) =>
          ConnectivityBanner(child: child ?? const SizedBox.shrink()),
      home: const _RootGate(),
    );
  }
}

/// Hosts the app shell and, on first launch, presents the onboarding screen as a
/// full-screen route over it. Keeping onboarding a pushed route (rather than a
/// conditional `home`) lets its "Open Settings" action navigate normally.
class _RootGate extends ConsumerStatefulWidget {
  const _RootGate();

  @override
  ConsumerState<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends ConsumerState<_RootGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(onboardingSeenProvider)) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const OnboardingScreen(),
          fullscreenDialog: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const HomeShell();
}
