import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_format.dart';
import '../../../auto_refresh/presentation/controllers/foreground_auto_refresh_controller.dart';
import '../../../auto_refresh/presentation/widgets/auto_refresh_status_card.dart';
import '../../../background_refresh/presentation/controllers/background_refresh_settings_controller.dart';
import '../../../background_refresh/presentation/widgets/background_refresh_settings_section.dart';
import '../controllers/settings_controller.dart';
import '../widgets/refresh_interval_selector.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.controller,
    this.autoRefreshController,
    this.backgroundRefreshController,
    required this.onClearLocalData,
  });

  final SettingsController controller;
  final ForegroundAutoRefreshController? autoRefreshController;
  final BackgroundRefreshSettingsController? backgroundRefreshController;
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
                    title: const Text('Foreground Auto Refresh'),
                    subtitle: const Text(
                      'Foreground only. Uses the current WebView page.',
                    ),
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Foreground only'),
                        Text('No background refresh'),
                        Text('No automatic login'),
                        Text('Uses current WebView page only'),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    title: const Text(
                      'Reload page before foreground auto refresh',
                    ),
                    subtitle: const Text(
                      'Only works while the app is in the foreground. Does not run in Android background tasks. May trigger login or page loading issues if used too frequently.',
                    ),
                    value: controller.reloadBeforeForegroundAutoRefreshEnabled,
                    onChanged: controller.isSaving
                        ? null
                        : controller
                              .setReloadBeforeForegroundAutoRefreshEnabled,
                  ),
                  if (controller.refreshInterval.duration != null &&
                      controller.refreshInterval.duration! <=
                          const Duration(minutes: 5))
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        'Frequent reloads may be unreliable. 15+ minutes is recommended.',
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
            if (autoRefreshController != null) ...[
              const SizedBox(height: 12),
              AutoRefreshStatusCard(controller: autoRefreshController!),
            ],
            if (backgroundRefreshController != null) ...[
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: backgroundRefreshController!,
                builder: (context, _) {
                  return BackgroundRefreshSettingsSection(
                    controller: backgroundRefreshController!,
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Reload page before manual refresh'),
                    subtitle: const Text(
                      'On by default because a manual tap usually means you want the newest rendered analytics page.',
                    ),
                    value: controller.reloadBeforeManualRefreshEnabled,
                    onChanged: controller.isSaving
                        ? null
                        : controller.setReloadBeforeManualRefreshEnabled,
                  ),
                  SwitchListTile(
                    title: const Text(
                      'Auto-save high confidence manual refresh',
                    ),
                    subtitle: const Text(
                      'Off by default. Medium confidence still requires confirmation.',
                    ),
                    value: controller.autoSaveHighConfidenceManualRefresh,
                    onChanged: controller.isSaving
                        ? null
                        : controller.setManualRefreshAutoSaveHighConfidence,
                  ),
                  const ListTile(
                    title: Text('Medium confidence manual refresh'),
                    subtitle: Text('Allowed only after user confirmation.'),
                  ),
                  const ListTile(
                    title: Text('Low confidence manual refresh'),
                    subtitle: Text('Saving disabled by default.'),
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
                      'Reload before manual refresh: ${controller.reloadBeforeManualRefreshEnabled ? 'On' : 'Off'}',
                    ),
                    Text(
                      'Reload before foreground auto refresh: ${controller.reloadBeforeForegroundAutoRefreshEnabled ? 'On' : 'Off'}',
                    ),
                    Text(
                      'Manual refresh auto-save high confidence: ${controller.autoSaveHighConfidenceManualRefresh ? 'On' : 'Off'}',
                    ),
                    const Text(
                      'Manual refresh medium confidence: confirmation required',
                    ),
                    const Text('Manual refresh low confidence: save disabled'),
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
                  children: const [
                    Text('Android Widget'),
                    SizedBox(height: 8),
                    Text('Widget updates after quota refresh/export/clear.'),
                    Text('Widget refresh opens the app refresh flow entry.'),
                    Text('Widget refresh updates widget view only.'),
                    Text('Widget does not refresh web page in background.'),
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
                      'Clears saved mock snapshots, snapshot history, widget summary export, persisted settings, redacted extracted text preview, and last manual refresh result.',
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
            'This removes only this app\'s saved mock quota snapshots, history, widget summary export, settings, redacted extracted text preview, and last manual refresh result.',
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
