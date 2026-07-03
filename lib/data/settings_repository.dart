import '../core/ai/ai_provider.dart';
import '../core/storage/secure_store.dart';

/// API keys live ONLY in secure storage, entered by the user (BYO-key).
/// No bundled/developer fallback: shipping a key inside the app would leak it
/// in the APK/IPA and let every user spend the developer's quota.
/// One key per provider; Gemini keeps its legacy storage name.
class SettingsRepository {
  SettingsRepository(this._store);

  final SecureStore _store;

  Future<String?> getKey(AiProvider provider) async {
    final stored = await _store.read(provider.storageKey);
    return (stored == null || stored.isEmpty) ? null : stored;
  }

  Future<void> setKey(AiProvider provider, String value) =>
      _store.write(provider.storageKey, value);
}
