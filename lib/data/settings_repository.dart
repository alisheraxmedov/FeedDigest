import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/storage/secure_store.dart';

class SettingsRepository {
  SettingsRepository(this._store);

  final SecureStore _store;

  static const String _geminiKey = 'gemini_api_key';

  Future<String?> getGeminiKey() async {
    final stored = await _store.read(_geminiKey);
    if (stored != null && stored.isNotEmpty) return stored;
    return _envGeminiKey();
  }

  Future<void> setGeminiKey(String value) => _store.write(_geminiKey, value);

  String? _envGeminiKey() {
    if (!dotenv.isInitialized) return null;
    final value = dotenv.maybeGet('GEMINI_API_KEY');
    return (value == null || value.isEmpty) ? null : value;
  }
}
