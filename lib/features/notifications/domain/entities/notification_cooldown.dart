import 'notification_metadata.dart';
import 'quota_notification_type.dart';

class NotificationCooldown {
  const NotificationCooldown(this.duration);

  final Duration duration;

  bool allows({
    required QuotaNotificationType type,
    required NotificationMetadata metadata,
    required DateTime now,
  }) {
    return !metadata.isCoolingDown(type: type, now: now, cooldown: duration);
  }
}
