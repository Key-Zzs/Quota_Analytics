import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../../quota/domain/entities/parser_confidence.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../../quota/domain/entities/quota_source.dart';
import '../../../quota/presentation/controllers/quota_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

class DebugPage extends StatelessWidget {
  const DebugPage({
    super.key,
    required this.controller,
    required this.settingsController,
    required this.onClearLocalData,
  });

  final QuotaController controller;
  final SettingsController settingsController;
  final Future<void> Function() onClearLocalData;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, settingsController]),
      builder: (context, _) {
        final snapshot = controller.snapshot;
        final persistence = controller.persistenceStatus;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DebugCard(
              title: 'Persistence',
              children: [
                _DebugRow(label: 'Persistence mode', value: persistence.mode),
                _DebugRow(
                  label: 'Storage backend',
                  value: persistence.storageBackend,
                ),
                _DebugRow(
                  label: 'Last snapshot exists',
                  value: persistence.lastSnapshotExists.toString(),
                ),
                _DebugRow(
                  label: 'History count',
                  value: persistence.historyCount.toString(),
                ),
                _DebugRow(
                  label: 'Current interval',
                  value: settingsController.refreshInterval.label,
                ),
                _DebugRow(
                  label: 'Auto refresh enabled',
                  value: settingsController.autoRefreshEnabled.toString(),
                ),
                _DebugRow(
                  label: 'Last load time',
                  value: formatDateTime(persistence.lastLoadTime),
                ),
                _DebugRow(
                  label: 'Last save time',
                  value: formatDateTime(persistence.lastSaveTime),
                ),
                _DebugRow(
                  label: 'Last persistence error',
                  value: persistence.lastError ?? 'none',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: controller.isLoading || settingsController.isSaving
                      ? null
                      : () => unawaited(_confirmClear(context)),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear local data'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DebugCard(
              title: 'Runtime',
              children: [
                _DebugRow(label: 'App mode', value: AppConstants.appMode),
                const _DebugRow(
                  label: 'Current data source',
                  value: 'MockQuotaDataSource + LocalQuotaDataSource',
                ),
                _DebugRow(
                  label: 'Snapshot source',
                  value: snapshot?.source.label ?? 'none',
                ),
                _DebugRow(
                  label: 'Last refresh result',
                  value: controller.lastRefreshResult,
                ),
                _DebugRow(
                  label: 'Last refresh duration',
                  value: formatDuration(controller.lastRefreshDuration),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DebugCard(
              title: 'Recent snapshots',
              children: [
                if (controller.history.isEmpty)
                  const Text('No persisted history yet.')
                else
                  ...controller.history
                      .take(10)
                      .map((snapshot) => _SnapshotSummary(snapshot: snapshot)),
              ],
            ),
            const SizedBox(height: 12),
            _DebugCard(
              title: 'Current QuotaSnapshot',
              children: [
                SelectableText(
                  snapshot?.toDebugText() ?? 'No snapshot loaded.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _DebugCard(
              title: 'Safety notice',
              children: [
                Text('No real login'),
                Text('No token access'),
                Text('No network request'),
                Text('No cookie reading'),
                SizedBox(height: 8),
                Text(AppConstants.stageNotice),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear local data?'),
          content: const Text(
            'This removes only this app\'s saved mock quota snapshots, history, and settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await onClearLocalData();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Local data cleared')));
  }
}

class _SnapshotSummary extends StatelessWidget {
  const _SnapshotSummary({required this.snapshot});

  final QuotaSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatDateTime(snapshot.capturedAt),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text('Source: ${snapshot.source.label}'),
              Text(
                '5-hour: ${_windowLine(snapshot.fiveHourWindow.remaining, snapshot.fiveHourWindow.used, snapshot.fiveHourWindow.limit)}',
              ),
              Text(
                'Weekly: ${_windowLine(snapshot.weeklyWindow.remaining, snapshot.weeklyWindow.used, snapshot.weeklyWindow.limit)}',
              ),
              Text(
                'Credits remaining: ${snapshot.creditsRemaining?.toStringAsFixed(2) ?? 'unknown'}',
              ),
              Text('Parser confidence: ${snapshot.parserConfidence.label}'),
            ],
          ),
        ),
      ),
    );
  }

  String _windowLine(int? remaining, int? used, int? limit) {
    return 'remaining ${remaining ?? 'unknown'} / used ${used ?? 'unknown'} / limit ${limit ?? 'unknown'}';
  }
}

class _DebugCard extends StatelessWidget {
  const _DebugCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label)),
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
