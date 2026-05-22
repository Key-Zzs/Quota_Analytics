import 'package:shared_preferences/shared_preferences.dart';

import 'json_storage.dart';

class SharedPreferencesStorage implements JsonStorage {
  const SharedPreferencesStorage(this._preferences);

  final SharedPreferences _preferences;

  static Future<SharedPreferencesStorage> create() async {
    final preferences = await SharedPreferences.getInstance();
    return SharedPreferencesStorage(preferences);
  }

  @override
  String get backendName => 'shared_preferences';

  @override
  Future<String?> readString(String key) async {
    return _preferences.getString(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }

  @override
  Future<void> removeAll(Iterable<String> keys) async {
    for (final key in keys) {
      await remove(key);
    }
  }
}
