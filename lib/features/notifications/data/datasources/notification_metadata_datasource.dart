import 'dart:convert';

import '../../../../core/storage/json_storage.dart';
import '../../../../core/storage/local_storage_keys.dart';
import '../../domain/entities/notification_metadata.dart';
import '../../domain/entities/quota_notification_type.dart';

class NotificationMetadataDataSource {
  const NotificationMetadataDataSource({required this.storage});

  final JsonStorage storage;

  Future<NotificationMetadata> load() async {
    final raw = await storage.readString(LocalStorageKeys.notificationMetadata);
    if (raw == null) {
      return NotificationMetadata.empty();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('notification metadata root is not a map');
      }
      return NotificationMetadata.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on Object {
      await storage.remove(LocalStorageKeys.notificationMetadata);
      return NotificationMetadata.empty();
    }
  }

  Future<void> save(NotificationMetadata metadata) async {
    await storage.writeString(
      LocalStorageKeys.notificationMetadata,
      jsonEncode(metadata.toJson()),
    );
  }

  Future<void> markSent({
    required QuotaNotificationType type,
    required DateTime sentAt,
  }) async {
    final metadata = await load();
    await save(metadata.markSent(type: type, sentAt: sentAt));
  }

  Future<void> clear() {
    return storage.remove(LocalStorageKeys.notificationMetadata);
  }
}
