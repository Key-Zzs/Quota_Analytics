import '../../../../core/serialization/date_time_converter.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/refresh_interval.dart';

class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    required super.autoRefreshEnabled,
    required super.refreshInterval,
    required super.updatedAt,
  });

  factory AppSettingsModel.fromEntity(AppSettings settings) {
    return AppSettingsModel(
      autoRefreshEnabled: settings.autoRefreshEnabled,
      refreshInterval: settings.refreshInterval,
      updatedAt: settings.updatedAt,
    );
  }

  factory AppSettingsModel.fromJson(
    Map<String, Object?> json, {
    required DateTime fallbackUpdatedAt,
  }) {
    final refreshInterval = refreshIntervalFromStorageKey(
      _readString(json['refreshInterval']),
    );
    final autoRefreshEnabled =
        _readBool(json['autoRefreshEnabled']) ?? !refreshInterval.isOff;

    return AppSettingsModel(
      autoRefreshEnabled: autoRefreshEnabled && !refreshInterval.isOff,
      refreshInterval: autoRefreshEnabled
          ? refreshInterval
          : RefreshInterval.off,
      updatedAt: dateTimeFromIso8601(json['updatedAt']) ?? fallbackUpdatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'autoRefreshEnabled': autoRefreshEnabled,
      'refreshInterval': refreshInterval.storageKey,
      'updatedAt': dateTimeToIso8601(updatedAt),
    };
  }

  static String? _readString(Object? value) {
    return value is String ? value : null;
  }

  static bool? _readBool(Object? value) {
    return value is bool ? value : null;
  }
}
