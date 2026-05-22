import 'package:flutter/material.dart';

import '../../domain/entities/quota_window.dart';

class QuotaStatusBar extends StatelessWidget {
  const QuotaStatusBar({super.key, required this.window});

  final QuotaWindow window;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(window.status, colorScheme);
    final percentage = window.remainingPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: window.remainingRatio ?? 0,
            color: statusColor,
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          percentage == null ? 'Remaining unknown' : '$percentage% remaining',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Color _statusColor(QuotaWindowStatus status, ColorScheme colorScheme) {
    return switch (status) {
      QuotaWindowStatus.ok => colorScheme.primary,
      QuotaWindowStatus.warning => colorScheme.tertiary,
      QuotaWindowStatus.critical => colorScheme.error,
      QuotaWindowStatus.unknown => colorScheme.outline,
    };
  }
}
