/*
Play/stop button for text-to-speech read-aloud. Checks voice availability for
the target locale on mount and hides itself when no voice exists (e.g. Uzbek on
most devices), so read-aloud only appears where it actually works.
*/
import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class ReadAloudButton extends StatefulWidget {
  const ReadAloudButton({
    super.key,
    required this.text,
    required this.langCode,
  });

  final String text;
  final String langCode;

  @override
  State<ReadAloudButton> createState() => _ReadAloudButtonState();
}

class _ReadAloudButtonState extends State<ReadAloudButton> {
  bool _available = false;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final ok = await TtsService.instance.isAvailableFor(widget.langCode);
    if (mounted) setState(() => _available = ok);
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_speaking) {
      await TtsService.instance.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    await TtsService.instance.speak(widget.text, langCode: widget.langCode);
    if (mounted) setState(() => _speaking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();
    final palette = AppPalette.of(context);
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: Icon(
        _speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
        color: palette.accent,
      ),
      onPressed: _toggle,
    );
  }
}
