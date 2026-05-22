import 'refresh_interval.dart';

class AppSettings {
  const AppSettings({
    required this.autoRefreshEnabled,
    required this.refreshInterval,
    required this.updatedAt,
  });

  factory AppSettings.defaults(DateTime updatedAt) {
    return AppSettings(
      autoRefreshEnabled: false,
      refreshInterval: RefreshInterval.off,
      updatedAt: updatedAt,
    );
  }

  final bool autoRefreshEnabled;
  final RefreshInterval refreshInterval;
  final DateTime updatedAt;

  AppSettings copyWith({
    bool? autoRefreshEnabled,
    RefreshInterval? refreshInterval,
    DateTime? updatedAt,
  }) {
    final nextInterval = refreshInterval ?? this.refreshInterval;
    final nextAutoRefreshEnabled =
        autoRefreshEnabled ?? this.autoRefreshEnabled;

    return AppSettings(
      autoRefreshEnabled: nextAutoRefreshEnabled && !nextInterval.isOff,
      refreshInterval: nextAutoRefreshEnabled
          ? nextInterval
          : RefreshInterval.off,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
