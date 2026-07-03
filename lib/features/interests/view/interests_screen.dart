/*
First-run interests screen (shown after onboarding). A grouped cloud of tappable
interest chips; the picks become topic Subscriptions that fill the feed. Continue
is disabled until at least one chip is selected; Skip seeds the default topics.
No feature logic lives here — selection + commit live in the view model.
*/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/interests.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/neon_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../viewmodel/interests_viewmodel.dart';

class InterestsScreen extends ConsumerWidget {
  const InterestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final selected = ref.watch(interestsSelectionProvider);

    Future<void> onContinue() async {
      final navigator = Navigator.of(context);
      await ref.read(interestsSelectionProvider.notifier).commit();
      navigator.pop();
    }

    Future<void> onSkip() async {
      final navigator = Navigator.of(context);
      await ref.read(interestsSelectionProvider.notifier).skipWithDefaults();
      navigator.pop();
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    l.interestsTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.interestsSubtitle,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: palette.textDim,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final group in InterestCatalog.groups) ...[
                            Text(
                              group.title.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: palette.textDim,
                              ),
                            ),
                            const SizedBox(height: 11),
                            Wrap(
                              spacing: 9,
                              runSpacing: 9,
                              children: [
                                for (final interest in group.interests)
                                  _InterestChip(
                                    label: interest.label,
                                    selected: selected.contains(interest.topic),
                                    onTap: () => ref
                                        .read(interestsSelectionProvider.notifier)
                                        .toggle(interest.topic),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 22),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 20),
                    child: Column(
                      children: [
                        NeonButton(
                          label: l.interestsContinue,
                          onPressed: selected.isEmpty ? null : onContinue,
                          height: 52,
                          radius: 15,
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: onSkip,
                          child: Text(
                            l.interestsSkip,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: palette.textDim,
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

/// A single selectable interest chip: brand gradient + check when selected,
/// outlined when not.
class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            gradient: selected ? palette.brandGradient : null,
            color: selected ? null : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : scheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 16, color: Colors.white),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
