import '../entities/background_refresh_settings.dart';
import '../repositories/background_refresh_repository.dart';

class ScheduleBackgroundRefresh {
  const ScheduleBackgroundRefresh(this.repository);

  final BackgroundRefreshRepository repository;

  Future<void> call(BackgroundRefreshSettings settings) {
    return repository.schedule(settings);
  }
}
