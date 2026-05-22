import '../repositories/settings_repository.dart';

class ClearAppSettings {
  const ClearAppSettings(this.repository);

  final SettingsRepository repository;

  Future<void> call() => repository.clearSettings();
}
