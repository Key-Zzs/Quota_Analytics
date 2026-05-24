enum NotificationPermissionStatus {
  granted,
  denied,
  unknown;

  String get label {
    return switch (this) {
      NotificationPermissionStatus.granted => 'granted',
      NotificationPermissionStatus.denied => 'denied',
      NotificationPermissionStatus.unknown => 'unknown',
    };
  }
}

abstract class NotificationPermissionService {
  Future<NotificationPermissionStatus> getStatus();

  Future<NotificationPermissionStatus> requestPermission();
}
