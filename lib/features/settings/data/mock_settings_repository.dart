import '../domain/entities/app_settings.dart';
import '../domain/entities/refresh_interval.dart';
import '../domain/repositories/settings_repository.dart';

class MockSettingsRepository implements SettingsRepository {
  MockSettingsRepository({DateTime? initialUpdatedAt})
    : _settings = AppSettings.defaults(
        initialUpdatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  AppSettings _settings;

  bool get autoRefreshEnabled => _settings.autoRefreshEnabled;
  RefreshInterval get refreshInterval => _settings.refreshInterval;

  void setAutoRefreshEnabled(bool value) {
    _settings = _settings.copyWith(
      autoRefreshEnabled: value,
      refreshInterval: value && _settings.refreshInterval.isOff
          ? RefreshInterval.fifteenMinutes
          : _settings.refreshInterval,
      updatedAt: DateTime.now(),
    );
  }

  void setRefreshInterval(RefreshInterval interval) {
    _settings = _settings.copyWith(
      autoRefreshEnabled: !interval.isOff,
      refreshInterval: interval,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<AppSettings> getSettings() async {
    return _settings;
  }

  @override
  Future<AppSettings> saveSettings(AppSettings settings) async {
    _settings = settings.copyWith(updatedAt: DateTime.now());
    return _settings;
  }

  @override
  Future<void> clearSettings() async {
    _settings = AppSettings.defaults(DateTime.now());
  }
}
