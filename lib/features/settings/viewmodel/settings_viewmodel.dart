import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

final geminiKeyPresentProvider = FutureProvider<bool>((ref) async {
  final key = await ref.watch(settingsRepositoryProvider).getGeminiKey();
  return key != null && key.isNotEmpty;
});

final settingsActionsProvider =
    Provider<SettingsActions>((ref) => SettingsActions(ref));

class SettingsActions {
  SettingsActions(this._ref);
  final Ref _ref;

  Future<void> saveKey(String value) async {
    await _ref.read(settingsRepositoryProvider).setGeminiKey(value.trim());
    _ref.invalidate(geminiKeyPresentProvider);
  }
}
