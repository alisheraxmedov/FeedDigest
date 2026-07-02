import '../core/storage/secure_store.dart';

/// The Gemini key lives ONLY in secure storage, entered by the user (BYO-key).
/// No bundled/developer fallback: shipping a key inside the app would leak it in
/// the APK/IPA and let every user spend the developer's quota.
class SettingsRepository {
  SettingsRepository(this._store);

  final SecureStore _store;

  static const String _geminiKey = 'gemini_api_key';

  Future<String?> getGeminiKey() async {
    final stored = await _store.read(_geminiKey);
    return (stored == null || stored.isEmpty) ? null : stored;
  }

  Future<void> setGeminiKey(String value) => _store.write(_geminiKey, value);
}
