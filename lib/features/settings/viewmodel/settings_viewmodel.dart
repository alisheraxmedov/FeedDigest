import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ai/ai_provider.dart';
import '../../../core/providers.dart';

/// Whether a key is stored for [provider]; drives the status pill per chip.
final aiKeyPresentProvider = FutureProvider.family<bool, AiProvider>((
  ref,
  provider,
) async {
  final key = await ref.watch(settingsRepositoryProvider).getKey(provider);
  return key != null && key.isNotEmpty;
});

final settingsActionsProvider = Provider<SettingsActions>(
  (ref) => SettingsActions(ref),
);

class SettingsActions {
  SettingsActions(this._ref);
  final Ref _ref;

  Future<void> saveKey(AiProvider provider, String value) async {
    await _ref.read(settingsRepositoryProvider).setKey(provider, value.trim());
    _ref.invalidate(aiKeyPresentProvider(provider));
  }
}
