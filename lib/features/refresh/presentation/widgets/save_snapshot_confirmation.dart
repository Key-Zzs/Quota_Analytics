import 'package:flutter/material.dart';

import '../../domain/entities/manual_refresh_result.dart';

Future<bool> showSaveSnapshotConfirmation(
  BuildContext context,
  ManualRefreshResult result,
) async {
  final warnings = result.warnings;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Save parsed snapshot?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This saves the parsed WebView manual refresh result locally as the latest quota snapshot and appends it to history.',
            ),
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Warnings: ${warnings.join(' | ')}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save Parsed Snapshot'),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}
