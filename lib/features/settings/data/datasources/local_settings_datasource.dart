import 'dart:convert';

import '../../../../core/storage/json_storage.dart';
import '../../../../core/storage/local_storage_keys.dart';
import '../../../../core/time/clock.dart';
import '../../domain/entities/app_settings.dart';
import '../models/app_settings_model.dart';

class LocalSettingsDataSource {
  LocalSettingsDataSource({required this.storage, required this.clock});

  final JsonStorage storage;
  final Clock clock;

  DateTime? lastLoadTime;
  DateTime? lastSaveTime;
  String? lastError;

  Future<AppSettingsModel?> loadSettings({
    required DateTime fallbackUpdatedAt,
  }) async {
    lastLoadTime = clock.now();
    lastError = null;

    final raw = await storage.readString(LocalStorageKeys.appSettings);
    if (raw == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('settings root is not a JSON object');
      }
      return AppSettingsModel.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
        fallbackUpdatedAt: fallbackUpdatedAt,
      );
    } on Object catch (error) {
      await storage.remove(LocalStorageKeys.appSettings);
      lastError = 'Failed to read settings: $error';
      return null;
    }
  }

  Future<AppSettingsModel> saveSettings(AppSettings settings) async {
    try {
      final model = AppSettingsModel.fromEntity(settings);
      await storage.writeString(
        LocalStorageKeys.appSettings,
        jsonEncode(model.toJson()),
      );
      lastSaveTime = clock.now();
      lastError = null;
      return model;
    } on Object catch (error) {
      lastSaveTime = clock.now();
      lastError = 'Failed to save settings: $error';
      rethrow;
    }
  }

  Future<void> clearSettings() async {
    await storage.remove(LocalStorageKeys.appSettings);
    lastSaveTime = clock.now();
    lastError = null;
  }
}
