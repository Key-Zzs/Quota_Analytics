import '../../../../core/permissions/notification_permission_service.dart';
import '../repositories/notification_repository.dart';

class RequestNotificationPermission {
  const RequestNotificationPermission(this.repository);

  final NotificationRepository repository;

  Future<NotificationPermissionStatus> call() {
    return repository.requestPermission();
  }
}
