import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_format.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../domain/entities/widget_export_status.dart';
import '../../domain/entities/widget_update_result.dart';
import '../controllers/widget_export_controller.dart';
import 'widget_summary_preview_card.dart';

class WidgetExportStatusCard extends StatelessWidget {
  const WidgetExportStatusCard({
    super.key,
    required this.controller,
    required this.latestSnapshot,
  });

  final WidgetExportController controller;
  final QuotaSnapshot? latestSnapshot;

  @override
  Widget build(BuildContext context) {
    final metadata = controller.metadata;
    final summary = controller.summary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Widget Export',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _Row(label: 'Widget export enabled', value: 'true'),
            _Row(
              label: 'Android widget shell available',
              value: controller.widgetShellStatus.availableLabel,
            ),
            _Row(
              label: 'Android widgets installed',
              value: controller.widgetShellStatus.installedLabel,
            ),
            _Row(
              label: 'Last widget export status',
              value: metadata.status.label,
            ),
            _Row(
              label: 'Last widget exported at',
              value: formatDateTime(metadata.lastExportedAt),
            ),
            _Row(
              label: 'Last widget export error',
              value: metadata.lastExportError ?? controller.lastError ?? 'none',
            ),
            _Row(
              label: 'Last widget update signal sent at',
              value: formatDateTime(controller.lastWidgetUpdateResult.sentAt),
            ),
            _Row(
              label: 'Last widget update reason',
              value: controller.lastWidgetUpdateReason ?? 'none',
            ),
            _Row(
              label: 'Last widget update status',
              value: controller.lastWidgetUpdateResult.status.label,
            ),
            _Row(
              label: 'Last widget update error',
              value: controller.lastWidgetUpdateError ?? 'none',
            ),
            _Row(
              label: 'Last widget click source',
              value: controller.lastWidgetLaunchSource ?? 'none',
            ),
            _Row(
              label: 'Last widget click target',
              value: controller.lastWidgetLaunchTarget ?? 'none',
            ),
            _Row(
              label: 'schemaVersion',
              value: summary?.schemaVersion ?? 'none',
            ),
            _Row(
              label: 'isStale',
              value: summary?.isStale.toString() ?? 'none',
            ),
            _Row(label: 'statusLabel', value: summary?.statusLabel ?? 'none'),
            _Row(label: 'source', value: summary?.source ?? 'none'),
            _Row(
              label: 'parserConfidence',
              value: summary?.parserConfidence ?? 'none',
            ),
            const SizedBox(height: 12),
            const Text('Widget reads display-safe summary only.'),
            const Text(
              'Widget does not login, parse pages, or access WebView.',
            ),
            const Text('Widget refresh updates the widget view only.'),
            const Text('Widget does not refresh the web page in background.'),
            const SizedBox(height: 12),
            WidgetSummaryPreviewCard(summary: summary),
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: controller.isBusy
                      ? null
                      : () => unawaited(controller.exportNow(latestSnapshot)),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('Export summary and update widgets now'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.isBusy
                      ? null
                      : () => unawaited(controller.updateWidgetsNow()),
                  icon: const Icon(Icons.widgets_outlined),
                  label: const Text('Update Android widgets now'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.isBusy
                      ? null
                      : () => unawaited(controller.clearSummary()),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear widget summary and update widgets'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 170, child: Text(label)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
