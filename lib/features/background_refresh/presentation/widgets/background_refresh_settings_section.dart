import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/permissions/notification_permission_service.dart';
import '../../../notifications/domain/entities/quota_notification_threshold.dart';
import '../controllers/background_refresh_settings_controller.dart';
import '../../domain/entities/background_check_interval.dart';
import '../../domain/entities/background_refresh_mode.dart';
import '../../domain/entities/background_stale_threshold.dart';

class BackgroundRefreshSettingsSection extends StatelessWidget {
  const BackgroundRefreshSettingsSection({
    super.key,
    required this.controller,
  });

  final BackgroundRefreshSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final settings = controller.settings;
    final notifications = settings.notificationSettings;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Android Background Refresh',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BackgroundRefreshMode>(
              initialValue: settings.mode,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Background refresh mode',
              ),
              selectedItemBuilder: (context) {
                return BackgroundRefreshMode.values
                    .map(
                      (mode) => Text(
                        mode.label,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )
                    .toList(growable: false);
              },
              items: BackgroundRefreshMode.values.map((mode) {
                final unavailable =
                    mode == BackgroundRefreshMode.backgroundSafeDataSourceOnly &&
                    !controller.backgroundSafeDataSourceAvailable;
                return DropdownMenuItem(
                  value: mode,
                  child: Text(
                    unavailable
                        ? '${mode.label} (experimental unavailable)'
                        : mode.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(growable: false),
              onChanged: controller.isBusy
                  ? null
                  : (value) {
                      if (value != null) {
                        controller.setMode(value);
                      }
                    },
            ),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Disabled')),
                Chip(label: Text('Notify only')),
                Chip(label: Text('Background-safe data source only')),
              ],
            ),
            if (!controller.backgroundSafeDataSourceAvailable) ...[
              const SizedBox(height: 8),
              const Text(
                'Background-safe data source only is experimental unavailable.',
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<BackgroundCheckInterval>(
              initialValue: settings.checkInterval,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Background check interval',
              ),
              items: BackgroundCheckInterval.values
                  .map(
                    (interval) => DropdownMenuItem(
                      value: interval,
                      child: Text(interval.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: controller.isBusy
                  ? null
                  : (value) {
                      if (value != null) {
                        controller.setCheckInterval(value);
                      }
                    },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable local notifications'),
              value: notifications.localNotificationsEnabled,
              onChanged: controller.isBusy
                  ? null
                  : controller.setLocalNotificationsEnabled,
            ),
            DropdownButtonFormField<BackgroundStaleThreshold>(
              initialValue: settings.staleDataThreshold,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Stale data threshold',
              ),
              items: BackgroundStaleThreshold.values
                  .map(
                    (threshold) => DropdownMenuItem(
                      value: threshold,
                      child: Text(threshold.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: controller.isBusy
                  ? null
                  : (value) {
                      if (value != null) {
                        controller.setStaleDataThreshold(value);
                      }
                    },
            ),
            const SizedBox(height: 12),
            _QuotaThresholdSelector(
              label: 'Low 5-hour quota threshold',
              value: notifications.lowFiveHourQuotaThreshold,
              onChanged: controller.setLowFiveHourQuotaThreshold,
              enabled: !controller.isBusy,
            ),
            const SizedBox(height: 12),
            _QuotaThresholdSelector(
              label: 'Low weekly quota threshold',
              value: notifications.lowWeeklyQuotaThreshold,
              onChanged: controller.setLowWeeklyQuotaThreshold,
              enabled: !controller.isBusy,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Refresh failure reminder'),
              value: notifications.refreshFailureReminderEnabled,
              onChanged: controller.isBusy
                  ? null
                  : controller.setRefreshFailureReminderEnabled,
            ),
            const SizedBox(height: 8),
            Text(
              'Notification permission status: ${controller.permissionStatus.label}',
            ),
            if (controller.permissionStatus !=
                NotificationPermissionStatus.granted) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: controller.isBusy
                    ? null
                    : () => unawaited(
                          controller.requestNotificationPermission(),
                        ),
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Request notification permission'),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Background refresh does not access WebView, cookies, tokens, or page text.',
            ),
            const Text(
              'Without an official API or background-safe data source, background mode only sends reminders based on the last saved snapshot.',
            ),
            const Text('Open the app to perform a real WebView refresh.'),
            if (controller.message != null) ...[
              const SizedBox(height: 8),
              Text(
                controller.message!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                controller.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.isBusy
                    ? null
                    : () => unawaited(controller.save()),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save background settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaThresholdSelector extends StatelessWidget {
  const _QuotaThresholdSelector({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final String label;
  final QuotaNotificationThreshold value;
  final ValueChanged<QuotaNotificationThreshold> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<QuotaNotificationThreshold>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: QuotaNotificationThreshold.values
          .map(
            (threshold) => DropdownMenuItem(
              value: threshold,
              child: Text(threshold.label),
            ),
          )
          .toList(growable: false),
      onChanged: enabled
          ? (value) {
              if (value != null) {
                onChanged(value);
              }
            }
          : null,
    );
  }
}
