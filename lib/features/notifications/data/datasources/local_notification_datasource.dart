import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../../core/permissions/notification_permission_service.dart';
import '../../domain/entities/notification_candidate.dart';

class LocalNotificationDataSource {
  LocalNotificationDataSource({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'quota_background_reminders';
  static const _channelName = 'Quota reminders';
  static const _channelDescription =
      'Local quota reminders based on saved app data.';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _initialized = true;
    } on MissingPluginException {
      _initialized = false;
    }
  }

  Future<NotificationPermissionStatus> getPermissionStatus() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final enabled = await android?.areNotificationsEnabled();
      if (enabled == null) {
        return NotificationPermissionStatus.unknown;
      }
      return enabled
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied;
    } on MissingPluginException {
      return NotificationPermissionStatus.unknown;
    }
  }

  Future<NotificationPermissionStatus> requestPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      if (granted == null) {
        return NotificationPermissionStatus.unknown;
      }
      return granted
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied;
    } on MissingPluginException {
      return NotificationPermissionStatus.unknown;
    }
  }

  Future<bool> show(NotificationCandidate candidate) async {
    if (!candidate.hasSafeContent) {
      return false;
    }
    await initialize();
    try {
      await _plugin.show(
        id: candidate.id,
        title: candidate.title,
        body: candidate.body,
        payload: candidate.payload,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            category: AndroidNotificationCategory.reminder,
          ),
        ),
      );
      return true;
    } on MissingPluginException {
      return false;
    }
  }
}
