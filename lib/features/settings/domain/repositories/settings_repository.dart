import '../entities/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();

  Future<AppSettings> saveSettings(AppSettings settings);

  Future<void> clearSettings();
}
