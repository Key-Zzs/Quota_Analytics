import '../../../../core/time/clock.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/refresh_interval.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local_settings_datasource.dart';

class LocalSettingsRepository implements SettingsRepository {
  const LocalSettingsRepository({
    required this.dataSource,
    required this.clock,
  });

  final LocalSettingsDataSource dataSource;
  final Clock clock;

  @override
  Future<AppSettings> getSettings() async {
    final now = clock.now();
    return await dataSource.loadSettings(fallbackUpdatedAt: now) ??
        AppSettings.defaults(now);
  }

  @override
  Future<AppSettings> saveSettings(AppSettings settings) {
    final normalized = _normalize(settings, updatedAt: clock.now());
    return dataSource.saveSettings(normalized);
  }

  @override
  Future<void> clearSettings() {
    return dataSource.clearSettings();
  }

  AppSettings _normalize(AppSettings settings, {required DateTime updatedAt}) {
    if (!settings.autoRefreshEnabled) {
      return AppSettings(
        autoRefreshEnabled: false,
        refreshInterval: RefreshInterval.off,
        updatedAt: updatedAt,
      );
    }

    return AppSettings(
      autoRefreshEnabled: true,
      refreshInterval: settings.refreshInterval.isOff
          ? RefreshInterval.fifteenMinutes
          : settings.refreshInterval,
      updatedAt: updatedAt,
    );
  }
}
