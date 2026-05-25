import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_format.dart';
import '../../domain/entities/widget_snapshot_summary.dart';

class WidgetSummaryPreviewCard extends StatelessWidget {
  const WidgetSummaryPreviewCard({super.key, required this.summary});

  final WidgetSnapshotSummary? summary;

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    if (summary == null) {
      return const Text('Latest widget summary preview: No data');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Latest widget summary preview'),
        const SizedBox(height: 8),
        Text('Display title: ${summary.displayTitle}'),
        Text('Display subtitle: ${summary.displaySubtitle}'),
        Text(
          '5-hour Remaining ratio: ${_ratio(summary.fiveHourRemainingRatio)}',
        ),
        Text('5-hour Reset time: ${summary.fiveHourResetText ?? 'unknown'}'),
        Text('5-hour reset at: ${formatDateTime(summary.fiveHourResetAt)}'),
        Text('Weekly Remaining ratio: ${_ratio(summary.weeklyRemainingRatio)}'),
        Text('Weekly Reset time: ${summary.weeklyResetText ?? 'unknown'}'),
        Text('Weekly reset at: ${formatDateTime(summary.weeklyResetAt)}'),
        Text(
          'Credits remaining: ${summary.creditsRemaining?.toStringAsFixed(2) ?? 'unknown'}',
        ),
        Text('Last updated: ${formatDateTime(summary.lastUpdatedAt)}'),
        Text('Exported at: ${formatDateTime(summary.exportedAt)}'),
      ],
    );
  }

  String _ratio(double? ratio) {
    if (ratio == null) {
      return 'unknown';
    }
    return '${(ratio * 100).round()}%';
  }
}
