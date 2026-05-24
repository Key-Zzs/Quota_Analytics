import '../../../../core/serialization/date_time_converter.dart';
import '../../../refresh/domain/entities/manual_refresh_policy.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/refresh_interval.dart';

class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    required super.autoRefreshEnabled,
    required super.refreshInterval,
    required super.manualRefreshPolicy,
    required super.updatedAt,
  });

  factory AppSettingsModel.fromEntity(AppSettings settings) {
    return AppSettingsModel(
      autoRefreshEnabled: settings.autoRefreshEnabled,
      refreshInterval: settings.refreshInterval,
      manualRefreshPolicy: settings.manualRefreshPolicy,
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
      manualRefreshPolicy: _readManualRefreshPolicy(
        json['manualRefreshPolicy'],
      ),
      updatedAt: dateTimeFromIso8601(json['updatedAt']) ?? fallbackUpdatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'autoRefreshEnabled': autoRefreshEnabled,
      'refreshInterval': refreshInterval.storageKey,
      'manualRefreshPolicy': {
        'autoSaveHighConfidence': manualRefreshPolicy.autoSaveHighConfidence,
        'requireConfirmationForMediumConfidence':
            manualRefreshPolicy.requireConfirmationForMediumConfidence,
        'allowLowConfidenceSave': manualRefreshPolicy.allowLowConfidenceSave,
      },
      'updatedAt': dateTimeToIso8601(updatedAt),
    };
  }

  static ManualRefreshPolicy _readManualRefreshPolicy(Object? value) {
    if (value is! Map) {
      return ManualRefreshPolicy.defaults();
    }
    final json = value.map(
      (key, mapValue) => MapEntry(key.toString(), mapValue),
    );
    return ManualRefreshPolicy(
      autoSaveHighConfidence:
          _readBool(json['autoSaveHighConfidence']) ?? false,
      requireConfirmationForMediumConfidence:
          _readBool(json['requireConfirmationForMediumConfidence']) ?? true,
      allowLowConfidenceSave:
          _readBool(json['allowLowConfidenceSave']) ?? false,
    );
  }

  static String? _readString(Object? value) {
    return value is String ? value : null;
  }

  static bool? _readBool(Object? value) {
    return value is bool ? value : null;
  }
}
