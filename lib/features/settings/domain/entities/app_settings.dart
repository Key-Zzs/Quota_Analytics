import '../../../refresh/domain/entities/manual_refresh_policy.dart';
import 'refresh_interval.dart';

class AppSettings {
  const AppSettings({
    required this.autoRefreshEnabled,
    required this.refreshInterval,
    required this.manualRefreshPolicy,
    required this.updatedAt,
  });

  factory AppSettings.defaults(DateTime updatedAt) {
    return AppSettings(
      autoRefreshEnabled: false,
      refreshInterval: RefreshInterval.off,
      manualRefreshPolicy: ManualRefreshPolicy.defaults(),
      updatedAt: updatedAt,
    );
  }

  final bool autoRefreshEnabled;
  final RefreshInterval refreshInterval;
  final ManualRefreshPolicy manualRefreshPolicy;
  final DateTime updatedAt;

  AppSettings copyWith({
    bool? autoRefreshEnabled,
    RefreshInterval? refreshInterval,
    ManualRefreshPolicy? manualRefreshPolicy,
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
      manualRefreshPolicy: manualRefreshPolicy ?? this.manualRefreshPolicy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
