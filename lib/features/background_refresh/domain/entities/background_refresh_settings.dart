import '../../../../core/serialization/date_time_converter.dart';
import '../../../notifications/domain/entities/notification_settings.dart';
import 'background_check_interval.dart';
import 'background_refresh_mode.dart';
import 'background_stale_threshold.dart';

class BackgroundRefreshSettings {
  const BackgroundRefreshSettings({
    required this.mode,
    required this.checkInterval,
    required this.staleDataThreshold,
    required this.notificationSettings,
    required this.minimumRunSpacing,
    required this.updatedAt,
  });

  factory BackgroundRefreshSettings.defaults(DateTime updatedAt) {
    return BackgroundRefreshSettings(
      mode: BackgroundRefreshMode.disabled,
      checkInterval: BackgroundCheckInterval.off,
      staleDataThreshold: BackgroundStaleThreshold.off,
      notificationSettings: NotificationSettings.defaults(),
      minimumRunSpacing: const Duration(minutes: 15),
      updatedAt: updatedAt,
    );
  }

  factory BackgroundRefreshSettings.fromJson(
    Map<String, Object?> json, {
    required DateTime fallbackUpdatedAt,
  }) {
    return BackgroundRefreshSettings(
      mode: backgroundRefreshModeFromStorageKey(_readString(json['mode'])),
      checkInterval: backgroundCheckIntervalFromStorageKey(
        _readString(json['checkInterval']),
      ),
      staleDataThreshold: backgroundStaleThresholdFromStorageKey(
        _readString(json['staleDataThreshold']),
      ),
      notificationSettings: NotificationSettings.fromJson(
        _readMap(json['notificationSettings']) ?? const {},
      ),
      minimumRunSpacing: Duration(
        minutes: _readInt(json['minimumRunSpacingMinutes']) ?? 15,
      ),
      updatedAt: dateTimeFromIso8601(json['updatedAt']) ?? fallbackUpdatedAt,
    );
  }

  final BackgroundRefreshMode mode;
  final BackgroundCheckInterval checkInterval;
  final BackgroundStaleThreshold staleDataThreshold;
  final NotificationSettings notificationSettings;
  final Duration minimumRunSpacing;
  final DateTime updatedAt;

  bool get shouldSchedule => mode != BackgroundRefreshMode.disabled &&
      !checkInterval.isOff;

  BackgroundRefreshSettings copyWith({
    BackgroundRefreshMode? mode,
    BackgroundCheckInterval? checkInterval,
    BackgroundStaleThreshold? staleDataThreshold,
    NotificationSettings? notificationSettings,
    Duration? minimumRunSpacing,
    DateTime? updatedAt,
  }) {
    final nextMode = mode ?? this.mode;
    final nextInterval = checkInterval ?? this.checkInterval;
    return BackgroundRefreshSettings(
      mode: nextMode,
      checkInterval: nextMode == BackgroundRefreshMode.disabled
          ? BackgroundCheckInterval.off
          : nextInterval,
      staleDataThreshold: staleDataThreshold ?? this.staleDataThreshold,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      minimumRunSpacing: minimumRunSpacing ?? this.minimumRunSpacing,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'mode': mode.storageKey,
      'checkInterval': checkInterval.storageKey,
      'staleDataThreshold': staleDataThreshold.storageKey,
      'notificationSettings': notificationSettings.toJson(),
      'minimumRunSpacingMinutes': minimumRunSpacing.inMinutes,
      'updatedAt': dateTimeToIso8601(updatedAt),
    };
  }

  static String? _readString(Object? value) {
    return value is String ? value : null;
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static Map<String, Object?>? _readMap(Object? value) {
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
    }
    return null;
  }
}
