import 'json_storage.dart';

class MemoryJsonStorage implements JsonStorage {
  final Map<String, String> _values = <String, String>{};

  @override
  String get backendName => 'memory';

  @override
  Future<String?> readString(String key) async {
    return _values[key];
  }

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> removeAll(Iterable<String> keys) async {
    for (final key in keys) {
      _values.remove(key);
    }
  }
}
