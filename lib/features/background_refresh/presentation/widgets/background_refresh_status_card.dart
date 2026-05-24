import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_format.dart';
import '../controllers/background_refresh_settings_controller.dart';

class BackgroundRefreshStatusCard extends StatelessWidget {
  const BackgroundRefreshStatusCard({
    super.key,
    required this.controller,
  });

  final BackgroundRefreshSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final settings = controller.settings;
    final result = controller.lastResult;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stage 8 Background Refresh',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Mode: ${settings.mode.label}'),
            Text('Interval: ${settings.checkInterval.label}'),
            Text('Stale threshold: ${settings.staleDataThreshold.label}'),
            Text(
              'Notification permission: ${controller.permissionStatus.label}',
            ),
            Text(
              'Background-safe data source available: ${controller.backgroundSafeDataSourceAvailable}',
            ),
            Text('Last background run status: ${result?.status.label ?? 'none'}'),
            Text('Last background run started: ${formatDateTime(result?.startedAt)}'),
            Text('Last background run finished: ${formatDateTime(result?.finishedAt)}'),
            Text('Notifications sent: ${result?.notificationsSent ?? 0}'),
            const SizedBox(height: 8),
            const Text('No hidden WebView background extraction'),
            const Text('No background cookie/token/storage access'),
            const Text('No background page text or HTML extraction'),
            const Text('No network upload'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: controller.isBusy
                  ? null
                  : () => unawaited(controller.runNow()),
              icon: const Icon(Icons.play_arrow_outlined),
              label: const Text('Run background check now'),
            ),
          ],
        ),
      ),
    );
  }
}
