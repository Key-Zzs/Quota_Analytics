abstract class JsonStorage {
  String get backendName;

  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);

  Future<void> remove(String key);

  Future<void> removeAll(Iterable<String> keys) async {
    for (final key in keys) {
      await remove(key);
    }
  }
}
