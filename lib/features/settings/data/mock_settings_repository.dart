import '../domain/entities/refresh_interval.dart';

class MockSettingsRepository {
  bool _autoRefreshEnabled = false;
  RefreshInterval _refreshInterval = RefreshInterval.off;

  bool get autoRefreshEnabled => _autoRefreshEnabled;
  RefreshInterval get refreshInterval => _refreshInterval;

  void setAutoRefreshEnabled(bool value) {
    _autoRefreshEnabled = value;
    if (!value) {
      _refreshInterval = RefreshInterval.off;
    } else if (_refreshInterval.isOff) {
      _refreshInterval = RefreshInterval.fifteenMinutes;
    }
  }

  void setRefreshInterval(RefreshInterval interval) {
    _refreshInterval = interval;
    _autoRefreshEnabled = !interval.isOff;
  }
}
