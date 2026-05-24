import '../../../../core/permissions/notification_permission_service.dart';
import '../entities/notification_candidate.dart';
import '../entities/notification_metadata.dart';
import '../entities/quota_notification_type.dart';

abstract class NotificationRepository {
  Future<NotificationPermissionStatus> getPermissionStatus();

  Future<NotificationPermissionStatus> requestPermission();

  Future<NotificationMetadata> getMetadata();

  Future<void> clearMetadata();

  Future<bool> send(NotificationCandidate candidate, {required DateTime now});

  Future<void> recordSent({
    required QuotaNotificationType type,
    required DateTime sentAt,
  });
}
