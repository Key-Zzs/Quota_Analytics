import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class GetAppSettings {
  const GetAppSettings(this.repository);

  final SettingsRepository repository;

  Future<AppSettings> call() => repository.getSettings();
}
