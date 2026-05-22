import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_format.dart';
import '../../domain/entities/quota_window.dart';
import 'quota_status_bar.dart';

class QuotaCard extends StatelessWidget {
  const QuotaCard({super.key, required this.window});

  final QuotaWindow window;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percentage = window.remainingPercentage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(window.label, style: theme.textTheme.titleMedium),
                ),
                _StatusChip(status: window.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              percentage == null ? '--%' : '$percentage%',
              style: theme.textTheme.displaySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${window.used ?? '--'} / ${window.limit ?? '--'} used',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            QuotaStatusBar(window: window),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reset: ${formatDateTime(window.resetAt)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final QuotaWindowStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = _foreground(status, colorScheme);
    final background = foreground.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _foreground(QuotaWindowStatus status, ColorScheme colorScheme) {
    return switch (status) {
      QuotaWindowStatus.ok => colorScheme.primary,
      QuotaWindowStatus.warning => colorScheme.tertiary,
      QuotaWindowStatus.critical => colorScheme.error,
      QuotaWindowStatus.unknown => colorScheme.outline,
    };
  }
}
