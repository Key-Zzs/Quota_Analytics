import 'quota_notification_threshold.dart';

class NotificationSettings {
  const NotificationSettings({
    required this.localNotificationsEnabled,
    required this.lowFiveHourQuotaThreshold,
    required this.lowWeeklyQuotaThreshold,
    required this.lowCreditsThreshold,
    required this.refreshFailureReminderEnabled,
    required this.cooldown,
  });

  factory NotificationSettings.defaults() {
    return const NotificationSettings(
      localNotificationsEnabled: false,
      lowFiveHourQuotaThreshold: QuotaNotificationThreshold.off,
      lowWeeklyQuotaThreshold: QuotaNotificationThreshold.off,
      lowCreditsThreshold: QuotaNotificationThreshold.off,
      refreshFailureReminderEnabled: true,
      cooldown: Duration(hours: 1),
    );
  }

  factory NotificationSettings.fromJson(Map<String, Object?> json) {
    return NotificationSettings(
      localNotificationsEnabled:
          _readBool(json['localNotificationsEnabled']) ?? false,
      lowFiveHourQuotaThreshold: quotaNotificationThresholdFromStorageKey(
        _readString(json['lowFiveHourQuotaThreshold']),
      ),
      lowWeeklyQuotaThreshold: quotaNotificationThresholdFromStorageKey(
        _readString(json['lowWeeklyQuotaThreshold']),
      ),
      lowCreditsThreshold: quotaNotificationThresholdFromStorageKey(
        _readString(json['lowCreditsThreshold']),
      ),
      refreshFailureReminderEnabled:
          _readBool(json['refreshFailureReminderEnabled']) ?? true,
      cooldown: Duration(minutes: _readInt(json['cooldownMinutes']) ?? 60),
    );
  }

  final bool localNotificationsEnabled;
  final QuotaNotificationThreshold lowFiveHourQuotaThreshold;
  final QuotaNotificationThreshold lowWeeklyQuotaThreshold;
  final QuotaNotificationThreshold lowCreditsThreshold;
  final bool refreshFailureReminderEnabled;
  final Duration cooldown;

  NotificationSettings copyWith({
    bool? localNotificationsEnabled,
    QuotaNotificationThreshold? lowFiveHourQuotaThreshold,
    QuotaNotificationThreshold? lowWeeklyQuotaThreshold,
    QuotaNotificationThreshold? lowCreditsThreshold,
    bool? refreshFailureReminderEnabled,
    Duration? cooldown,
  }) {
    return NotificationSettings(
      localNotificationsEnabled:
          localNotificationsEnabled ?? this.localNotificationsEnabled,
      lowFiveHourQuotaThreshold:
          lowFiveHourQuotaThreshold ?? this.lowFiveHourQuotaThreshold,
      lowWeeklyQuotaThreshold:
          lowWeeklyQuotaThreshold ?? this.lowWeeklyQuotaThreshold,
      lowCreditsThreshold: lowCreditsThreshold ?? this.lowCreditsThreshold,
      refreshFailureReminderEnabled:
          refreshFailureReminderEnabled ?? this.refreshFailureReminderEnabled,
      cooldown: cooldown ?? this.cooldown,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'localNotificationsEnabled': localNotificationsEnabled,
      'lowFiveHourQuotaThreshold': lowFiveHourQuotaThreshold.storageKey,
      'lowWeeklyQuotaThreshold': lowWeeklyQuotaThreshold.storageKey,
      'lowCreditsThreshold': lowCreditsThreshold.storageKey,
      'refreshFailureReminderEnabled': refreshFailureReminderEnabled,
      'cooldownMinutes': cooldown.inMinutes,
    };
  }

  static String? _readString(Object? value) {
    return value is String ? value : null;
  }

  static bool? _readBool(Object? value) {
    return value is bool ? value : null;
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
}
