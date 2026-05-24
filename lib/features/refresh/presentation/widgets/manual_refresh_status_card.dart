import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_format.dart';
import '../../../quota/domain/entities/parser_confidence.dart';
import '../controllers/manual_refresh_controller.dart';

class ManualRefreshStatusCard extends StatelessWidget {
  const ManualRefreshStatusCard({super.key, required this.controller});

  final ManualRefreshController controller;

  @override
  Widget build(BuildContext context) {
    final result = controller.lastResult;
    final summary = result.redactionSummary;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manual refresh status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (result.status.isActive) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],
            _StatusRow(label: 'Status', value: result.status.label),
            _StatusRow(
              label: 'Safety status',
              value: result.safetyStatus.label,
            ),
            _StatusRow(
              label: 'Parser confidence',
              value: result.parserConfidence.label,
            ),
            _StatusRow(
              label: 'Duration',
              value: formatDuration(result.duration),
            ),
            _StatusRow(
              label: 'Started at',
              value: formatDateTime(result.startedAt),
            ),
            _StatusRow(
              label: 'Finished at',
              value: formatDateTime(result.finishedAt),
            ),
            _StatusRow(
              label: 'Last saved snapshot id',
              value: result.savedSnapshotId ?? 'none',
            ),
            if (summary != null) ...[
              const SizedBox(height: 8),
              Text(
                'Redaction summary',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              _StatusRow(
                label: 'Lengths',
                value:
                    '${summary.originalLength} original / ${summary.redactedLength} redacted',
              ),
              _StatusRow(
                label: 'Counts',
                value:
                    'email ${summary.redactedEmailCount}, token ${summary.redactedTokenCount}, apiKey ${summary.redactedApiKeyCount}, secret ${summary.redactedSecretCount}',
              ),
              _StatusRow(
                label: 'Truncated',
                value: summary.truncated.toString(),
              ),
            ],
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Warnings: ${result.warnings.join(' | ')}'),
            ],
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Errors: ${result.errors.join(' | ')}'),
            ],
            const SizedBox(height: 8),
            const Text('Automatic refresh: disabled'),
            const Text('Background refresh: disabled'),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
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
