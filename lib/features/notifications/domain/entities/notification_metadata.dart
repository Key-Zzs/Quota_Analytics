import '../../../../core/serialization/date_time_converter.dart';
import 'quota_notification_type.dart';

class NotificationMetadata {
  const NotificationMetadata({required this.lastSentAtByType});

  factory NotificationMetadata.empty() {
    return const NotificationMetadata(lastSentAtByType: {});
  }

  factory NotificationMetadata.fromJson(Map<String, Object?> json) {
    final values = <QuotaNotificationType, DateTime>{};
    for (final type in QuotaNotificationType.values) {
      final sentAt = dateTimeFromIso8601(json[type.storageKey]);
      if (sentAt != null) {
        values[type] = sentAt;
      }
    }
    return NotificationMetadata(lastSentAtByType: values);
  }

  final Map<QuotaNotificationType, DateTime> lastSentAtByType;

  DateTime? lastSentAt(QuotaNotificationType type) {
    return lastSentAtByType[type];
  }

  bool isCoolingDown({
    required QuotaNotificationType type,
    required DateTime now,
    required Duration cooldown,
  }) {
    final lastSentAt = this.lastSentAt(type);
    if (lastSentAt == null) {
      return false;
    }
    return now.difference(lastSentAt) < cooldown;
  }

  NotificationMetadata markSent({
    required QuotaNotificationType type,
    required DateTime sentAt,
  }) {
    return NotificationMetadata(
      lastSentAtByType: {...lastSentAtByType, type: sentAt},
    );
  }

  Map<String, Object?> toJson() {
    return {
      for (final entry in lastSentAtByType.entries)
        entry.key.storageKey: dateTimeToIso8601(entry.value),
    };
  }
}
