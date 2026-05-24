import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_format.dart';
import '../../domain/entities/parsed_quota_window.dart';
import '../../domain/entities/quota_window_type.dart';

class ParsedWindowCard extends StatelessWidget {
  const ParsedWindowCard({super.key, required this.window});

  final ParsedQuotaWindow window;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(window.type.label, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _Field(
              label: 'Remaining ratio',
              value: window.remainingRatio == null
                  ? 'unknown'
                  : '${(window.remainingRatio! * 100).round()}%',
            ),
            _Field(label: 'Reset time', value: _resetTimeValue(window)),
            if (window.evidenceLabels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Evidence', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              ...window.evidenceLabels.map((evidence) => Text('- $evidence')),
            ],
          ],
        ),
      ),
    );
  }

  String _resetTimeValue(ParsedQuotaWindow window) {
    if (window.resetAt != null) {
      return formatDateTime(window.resetAt);
    }
    return window.resetText ?? 'unknown';
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label)),
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
