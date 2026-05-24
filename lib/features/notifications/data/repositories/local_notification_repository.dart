import '../../../../core/permissions/notification_permission_service.dart';
import '../../../../core/time/clock.dart';
import '../../domain/entities/notification_candidate.dart';
import '../../domain/entities/notification_metadata.dart';
import '../../domain/entities/quota_notification_type.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/local_notification_datasource.dart';
import '../datasources/notification_metadata_datasource.dart';

class LocalNotificationRepository implements NotificationRepository {
  const LocalNotificationRepository({
    required this.notificationDataSource,
    required this.metadataDataSource,
    required this.clock,
  });

  final LocalNotificationDataSource notificationDataSource;
  final NotificationMetadataDataSource metadataDataSource;
  final Clock clock;

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() {
    return notificationDataSource.getPermissionStatus();
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() {
    return notificationDataSource.requestPermission();
  }

  @override
  Future<NotificationMetadata> getMetadata() {
    return metadataDataSource.load();
  }

  @override
  Future<void> clearMetadata() {
    return metadataDataSource.clear();
  }

  @override
  Future<bool> send(
    NotificationCandidate candidate, {
    required DateTime now,
  }) async {
    final permission = await getPermissionStatus();
    if (permission == NotificationPermissionStatus.denied) {
      return false;
    }
    final sent = await notificationDataSource.show(candidate);
    if (sent) {
      await recordSent(type: candidate.type, sentAt: now);
    }
    return sent;
  }

  @override
  Future<void> recordSent({
    required QuotaNotificationType type,
    required DateTime sentAt,
  }) {
    return metadataDataSource.markSent(type: type, sentAt: sentAt);
  }
}
