/*
Hold-to-talk voice search button. Press and hold to record a spoken request;
release to send it to the AI, which fills the Search screen and switches to it.
The pulse AnimationController is disposed with the widget; all recorder/temp-file
cleanup lives in VoiceSearchController.
*/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ai/ai_provider.dart';
import '../../../core/prefs/preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../shell/viewmodel/home_tab_viewmodel.dart';
import '../viewmodel/voice_search_viewmodel.dart';

class VoiceSearchFab extends ConsumerStatefulWidget {
  const VoiceSearchFab({super.key, this.bottomInset = 90});

  /// Extra bottom gap so the button clears the HomeShell nav bar.
  final double bottomInset;

  @override
  ConsumerState<VoiceSearchFab> createState() => _VoiceSearchFabState();
}

class _VoiceSearchFabState extends ConsumerState<VoiceSearchFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _handleError(String code) {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    ref.read(voiceSearchProvider.notifier).acknowledge();
    if (code == 'no_key') {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.summaryNoKey),
          action: SnackBarAction(
            label: l.summaryAddKey,
            onPressed: () => ref
                .read(homeTabProvider.notifier)
                .select(HomeTabController.settings),
          ),
        ),
      );
      return;
    }
    final message = switch (code) {
      'no_permission' => l.voiceNoPermission,
      'empty' => l.voiceEmpty,
      _ => l.voiceFailed,
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // Voice search understands audio through Gemini only — hide the button
    // entirely when another provider is active (Settings explains why).
    if (ref.watch(aiProviderProvider) != AiProvider.gemini) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final state = ref.watch(voiceSearchProvider);

    ref.listen<VoiceSearchState>(voiceSearchProvider, (previous, next) {
      if (next.phase == VoicePhase.recording) {
        if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
      } else {
        _pulse.stop();
        _pulse.value = 0;
      }
      if (next.errorCode != null && next.errorCode != previous?.errorCode) {
        _handleError(next.errorCode!);
      }
    });

    final recording = state.phase == VoicePhase.recording;
    final processing = state.phase == VoicePhase.processing;
    final notifier = ref.read(voiceSearchProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (recording || processing)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HintPill(
                label: recording ? l.voiceListening : l.voiceProcessing,
              ),
            ),
          Semantics(
            button: true,
            label: l.voiceHoldHint,
            child: Listener(
              onPointerDown: (_) {
                if (state.phase == VoicePhase.idle) notifier.start();
              },
              onPointerUp: (_) => notifier.stopAndSearch(),
              onPointerCancel: (_) => notifier.cancel(),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) => Transform.scale(
                  scale: recording ? 1 + _pulse.value * 0.08 : 1.0,
                  child: child,
                ),
                child: _button(palette, recording, processing),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(AppPalette palette, bool recording, bool processing) {
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: palette.brandGradient,
        boxShadow: [
          BoxShadow(
            color: (recording ? Colors.redAccent : palette.accent).withValues(
              alpha: 0.45,
            ),
            blurRadius: 22,
            spreadRadius: recording ? 2 : -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: processing
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: palette.onAccent,
              ),
            )
          : Icon(
              recording ? Icons.mic : Icons.mic_none,
              color: palette.onAccent,
              size: 28,
            ),
    );
  }
}

class _HintPill extends StatelessWidget {
  const _HintPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: palette.cardColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.mutedBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
