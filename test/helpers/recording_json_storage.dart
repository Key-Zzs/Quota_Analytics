import 'package:quota_analytics/core/storage/json_storage.dart';

class RecordingJsonStorage implements JsonStorage {
  final Map<String, String> values = <String, String>{};

  @override
  String get backendName => 'recording';

  @override
  Future<String?> readString(String key) async {
    return values[key];
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> removeAll(Iterable<String> keys) async {
    for (final key in keys) {
      values.remove(key);
    }
  }

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }
}
