import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/permissions/notification_permission_service.dart';
import 'package:quota_analytics/features/notifications/domain/entities/notification_candidate.dart';
import 'package:quota_analytics/features/notifications/domain/entities/notification_metadata.dart';
import 'package:quota_analytics/features/notifications/domain/entities/quota_notification_type.dart';
import 'package:quota_analytics/features/notifications/domain/repositories/notification_repository.dart';
import 'package:quota_analytics/features/notifications/domain/usecases/send_quota_notification.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12);

  test('permission granted -> send and stores lastSentAt', () async {
    final repository = _FakeNotificationRepository();
    final sent = await SendQuotaNotification(
      repository,
    )(NotificationCandidate.staleData(), now: now);

    expect(sent, isTrue);
    expect(repository.sent.single.type, QuotaNotificationType.staleData);
    expect(
      repository.metadata.lastSentAt(QuotaNotificationType.staleData),
      now,
    );
  });

  test('permission denied -> not send', () async {
    final repository = _FakeNotificationRepository(
      permissionStatus: NotificationPermissionStatus.denied,
    );
    final sent = await SendQuotaNotification(
      repository,
    )(NotificationCandidate.staleData(), now: now);

    expect(sent, isFalse);
    expect(repository.sent, isEmpty);
  });

  test('duplicate skipped by fake repository cooldown', () async {
    final repository = _FakeNotificationRepository();
    await SendQuotaNotification(
      repository,
    )(NotificationCandidate.staleData(), now: now);
    final second = await SendQuotaNotification(repository)(
      NotificationCandidate.staleData(),
      now: now.add(const Duration(minutes: 5)),
    );

    expect(second, isFalse);
    expect(repository.sent, hasLength(1));
  });
}

class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository({
    this.permissionStatus = NotificationPermissionStatus.granted,
  });

  NotificationPermissionStatus permissionStatus;
  NotificationMetadata metadata = NotificationMetadata.empty();
  final sent = <NotificationCandidate>[];

  @override
  Future<void> clearMetadata() async {
    metadata = NotificationMetadata.empty();
  }

  @override
  Future<NotificationMetadata> getMetadata() async => metadata;

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async =>
      permissionStatus;

  @override
  Future<void> recordSent({
    required QuotaNotificationType type,
    required DateTime sentAt,
  }) async {
    metadata = metadata.markSent(type: type, sentAt: sentAt);
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async =>
      permissionStatus;

  @override
  Future<bool> send(
    NotificationCandidate candidate, {
    required DateTime now,
  }) async {
    if (permissionStatus == NotificationPermissionStatus.denied) {
      return false;
    }
    if (metadata.isCoolingDown(
      type: candidate.type,
      now: now,
      cooldown: const Duration(hours: 1),
    )) {
      return false;
    }
    sent.add(candidate);
    await recordSent(type: candidate.type, sentAt: now);
    return true;
  }
}
