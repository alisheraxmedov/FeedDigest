/*
Voice search. Records a short spoken query (record → temp WAV), sends the audio
to Gemini which returns a concise search query, then pushes that query into the
Search screen and switches to the Search tab.

Resource hygiene is deliberate: the native AudioRecorder is created per capture
and always disposed (on stop, cancel, or provider disposal), and the temp file
is always deleted — so nothing leaks between takes.
*/
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../core/providers.dart';
import '../../../core/ai/ai_client.dart';
import '../../search/viewmodel/pending_search_provider.dart';
import '../../shell/viewmodel/home_tab_viewmodel.dart';

enum VoicePhase { idle, recording, processing }

class VoiceSearchState {
  const VoiceSearchState({this.phase = VoicePhase.idle, this.errorCode});

  final VoicePhase phase;

  /// Set once when a capture fails; the UI shows it then calls [acknowledge].
  final String? errorCode;
}

final voiceSearchProvider =
    NotifierProvider<VoiceSearchController, VoiceSearchState>(
      VoiceSearchController.new,
    );

class VoiceSearchController extends Notifier<VoiceSearchState> {
  AudioRecorder? _recorder;
  String? _path;
  DateTime? _startedAt;

  /// Set when the press is released before recording has actually begun (the
  /// permission/start awaits are still in flight); [start] then stops itself.
  bool _stopRequested = false;

  /// Below this the release is treated as an accidental tap and dropped.
  static const Duration _minRecording = Duration(milliseconds: 500);

  @override
  VoiceSearchState build() {
    ref.onDispose(_cleanup);
    return const VoiceSearchState();
  }

  Future<void> start() async {
    if (state.phase != VoicePhase.idle) return;
    _stopRequested = false;
    final recorder = AudioRecorder();
    try {
      if (!await recorder.hasPermission()) {
        await recorder.dispose();
        state = const VoiceSearchState(errorCode: 'no_permission');
        return;
      }
      // Released during the permission check — never actually record.
      if (_stopRequested) {
        await recorder.dispose();
        state = const VoiceSearchState();
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_query_${DateTime.now().millisecondsSinceEpoch}.wav';
      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: path,
      );
      _recorder = recorder;
      _path = path;
      _startedAt = DateTime.now();
      state = const VoiceSearchState(phase: VoicePhase.recording);
      // Released while start() was awaiting — stop right away.
      if (_stopRequested) await stopAndSearch();
    } catch (_) {
      await recorder.dispose();
      state = const VoiceSearchState(errorCode: 'record');
    }
  }

  Future<void> stopAndSearch() async {
    if (state.phase != VoicePhase.recording) {
      // Released before recording began; start() will honor this.
      _stopRequested = true;
      return;
    }
    _stopRequested = false;
    final tooShort =
        _startedAt != null &&
        DateTime.now().difference(_startedAt!) < _minRecording;
    final recorder = _recorder;
    _recorder = null;
    _startedAt = null;

    String? path;
    try {
      path = await recorder?.stop();
    } catch (_) {
      // fall through — handled by the null-path check below
    }
    await recorder?.dispose();

    if (tooShort) {
      await _deleteTemp();
      state = const VoiceSearchState();
      return;
    }
    if (path == null) {
      await _deleteTemp();
      state = const VoiceSearchState(errorCode: 'record');
      return;
    }

    state = const VoiceSearchState(phase: VoicePhase.processing);
    try {
      final bytes = await File(path).readAsBytes();
      if (bytes.isEmpty) {
        state = const VoiceSearchState(errorCode: 'empty');
        return;
      }
      final query = (await ref
              .read(aiRepositoryProvider)
              .voiceQuery(bytes, mimeType: 'audio/wav'))
          .trim();
      if (!ref.mounted) return;
      if (query.isEmpty) {
        state = const VoiceSearchState(errorCode: 'empty');
        return;
      }
      // Hand the query to the Search screen and reveal it. The Search screen
      // fills its field and runs the query off pendingSearchProvider.
      ref.read(pendingSearchProvider.notifier).submit(query);
      ref.read(homeTabProvider.notifier).select(HomeTabController.search);
      state = const VoiceSearchState();
    } on AiException catch (e) {
      if (!ref.mounted) return;
      state = VoiceSearchState(errorCode: e.code);
    } catch (_) {
      if (!ref.mounted) return;
      state = const VoiceSearchState(errorCode: 'unknown');
    } finally {
      await _deleteTemp();
    }
  }

  Future<void> cancel() async {
    if (state.phase != VoicePhase.recording) {
      _stopRequested = true; // abort a start() still in flight
      return;
    }
    final recorder = _recorder;
    _recorder = null;
    _startedAt = null;
    try {
      await recorder?.stop();
    } catch (_) {}
    await recorder?.dispose();
    await _deleteTemp();
    if (state.phase != VoicePhase.idle) {
      state = const VoiceSearchState();
    }
  }

  /// Clears a surfaced error back to idle after the UI has shown it.
  void acknowledge() {
    if (state.errorCode != null) state = const VoiceSearchState();
  }

  Future<void> _deleteTemp() async {
    final path = _path;
    _path = null;
    if (path == null) return;
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }

  Future<void> _cleanup() async {
    final recorder = _recorder;
    _recorder = null;
    _startedAt = null;
    try {
      await recorder?.stop();
    } catch (_) {}
    await recorder?.dispose();
    await _deleteTemp();
  }
}
