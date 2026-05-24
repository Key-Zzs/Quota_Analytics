import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_format.dart';
import '../controllers/foreground_auto_refresh_controller.dart';

class AutoRefreshStatusCard extends StatelessWidget {
  const AutoRefreshStatusCard({super.key, required this.controller});

  final ForegroundAutoRefreshController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Foreground Auto Refresh status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _StatusLine(label: 'Enabled', value: state.enabled.toString()),
            _StatusLine(label: 'Interval', value: state.interval.label),
            _StatusLine(label: 'Status', value: state.status.label),
            _StatusLine(
              label: 'Lifecycle',
              value: controller.lifecycleState.name,
            ),
            _StatusLine(
              label: 'Last attempt',
              value: formatDateTime(state.lastAttemptAt),
            ),
            _StatusLine(
              label: 'Last success',
              value: formatDateTime(state.lastSuccessAt),
            ),
            _StatusLine(
              label: 'Next eligible',
              value: formatDateTime(state.nextEligibleAt),
            ),
            _StatusLine(label: 'Last error', value: state.lastError ?? 'none'),
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
