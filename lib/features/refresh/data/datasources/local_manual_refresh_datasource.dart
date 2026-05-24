import 'dart:convert';

import '../../../../core/storage/json_storage.dart';
import '../../../../core/storage/local_storage_keys.dart';
import '../../../../core/time/clock.dart';
import '../models/manual_refresh_result_model.dart';

class LocalManualRefreshDataSource {
  LocalManualRefreshDataSource({required this.storage, required this.clock});

  final JsonStorage storage;
  final Clock clock;

  DateTime? lastLoadTime;
  DateTime? lastSaveTime;
  String? lastError;

  Future<ManualRefreshResultModel?> loadLast() async {
    lastLoadTime = clock.now();
    lastError = null;

    final raw = await storage.readString(LocalStorageKeys.manualRefreshResult);
    if (raw == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('manual refresh root is not a JSON object');
      }
      return ManualRefreshResultModel.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on Object catch (error) {
      await storage.remove(LocalStorageKeys.manualRefreshResult);
      lastError = 'Failed to read manual refresh result: $error';
      return null;
    }
  }

  Future<ManualRefreshResultModel> saveLast(
    ManualRefreshResultModel result,
  ) async {
    try {
      await storage.writeString(
        LocalStorageKeys.manualRefreshResult,
        jsonEncode(result.toJson()),
      );
      lastSaveTime = clock.now();
      lastError = null;
      return result;
    } on Object catch (error) {
      lastSaveTime = clock.now();
      lastError = 'Failed to save manual refresh result: $error';
      rethrow;
    }
  }

  Future<void> clearLast() async {
    await storage.remove(LocalStorageKeys.manualRefreshResult);
    lastSaveTime = clock.now();
    lastError = null;
  }
}
