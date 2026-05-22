import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class SaveAppSettings {
  const SaveAppSettings(this.repository);

  final SettingsRepository repository;

  Future<AppSettings> call(AppSettings settings) {
    return repository.saveSettings(settings);
  }
}
