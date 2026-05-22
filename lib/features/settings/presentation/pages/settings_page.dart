import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_format.dart';
import '../controllers/settings_controller.dart';
import '../widgets/refresh_interval_selector.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.controller,
    required this.onClearLocalData,
  });

  final SettingsController controller;
  final Future<void> Function() onClearLocalData;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.status == SettingsStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Automatic refresh'),
                    subtitle: const Text('Saved locally for future stages'),
                    value: controller.autoRefreshEnabled,
                    onChanged: controller.isSaving
                        ? null
                        : controller.setAutoRefreshEnabled,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: RefreshIntervalSelector(
                      selected: controller.refreshInterval,
                      onChanged: controller.isSaving
                          ? (_) {}
                          : controller.setRefreshInterval,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: controller.isSaving
                            ? null
                            : () => unawaited(controller.save()),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save settings'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Persisted settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Auto refresh: ${controller.autoRefreshEnabled ? 'On' : 'Off'}',
                    ),
                    Text('Interval: ${controller.refreshInterval.label}'),
                    Text(
                      'Settings updated: ${formatDateTime(controller.settings?.updatedAt)}',
                    ),
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
                    if (controller.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        controller.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local data',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Clears saved mock snapshots, snapshot history, and persisted settings.',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: controller.isSaving
                          ? null
                          : () => unawaited(_confirmClear(context)),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Clear local data'),
                    ),
                  ],
                ),
              ),
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
