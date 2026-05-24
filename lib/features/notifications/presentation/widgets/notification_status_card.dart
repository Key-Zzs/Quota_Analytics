import 'package:flutter/material.dart';

import '../../../../core/permissions/notification_permission_service.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../domain/entities/notification_metadata.dart';
import '../../domain/entities/quota_notification_type.dart';

class NotificationStatusCard extends StatelessWidget {
  const NotificationStatusCard({
    super.key,
    required this.permissionStatus,
    required this.metadata,
  });

  final NotificationPermissionStatus permissionStatus;
  final NotificationMetadata metadata;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification cooldown state',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Permission status: ${permissionStatus.label}'),
            const SizedBox(height: 8),
            for (final type in QuotaNotificationType.values)
              Text(
                '${type.storageKey}: ${formatDateTime(metadata.lastSentAt(type))}',
              ),
          ],
        ),
      ),
    );
  }
}
