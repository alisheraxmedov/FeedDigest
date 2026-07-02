/*
Text-to-speech read-aloud for AI summaries and the daily digest.

Reality check: Uzbek TTS voices are absent on iOS and unreliable on Android, and
article content is mostly English anyway — so callers gate on [isAvailableFor]
and the UI hides/disables read-aloud when no voice exists for the target locale.
Markdown is stripped before speaking so the listener doesn't hear "hash hash".
*/
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _awaitConfigured = false;

  static String _bcp47(String langCode) => switch (langCode) {
    'ru' => 'ru-RU',
    'en' => 'en-US',
    _ => 'uz-UZ',
  };

  Future<bool> isAvailableFor(String langCode) async {
    try {
      final result = await _tts.isLanguageAvailable(_bcp47(langCode));
      // Platforms return a bool or a 0/1 int; treat anything truthy as available.
      return result == true || result == 1;
    } catch (_) {
      return false;
    }
  }

  /// Speaks [text]. The returned future completes when the utterance finishes
  /// (or is stopped), so callers can reset their play/stop state.
  Future<void> speak(String text, {required String langCode}) async {
    final clean = _strip(text);
    if (clean.isEmpty) return;
    if (!_awaitConfigured) {
      await _tts.awaitSpeakCompletion(true);
      _awaitConfigured = true;
    }
    await _tts.stop();
    await _tts.setLanguage(_bcp47(langCode));
    await _tts.setSpeechRate(0.5);
    await _tts.speak(clean);
  }

  Future<void> stop() => _tts.stop();

  /// Strips Markdown so the reader hears prose, not syntax.
  String _strip(String md) => md
      .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
      .replaceAll(RegExp(r'[#*`>_\[\]()-]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
