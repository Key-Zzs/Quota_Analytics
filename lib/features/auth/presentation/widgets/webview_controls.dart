import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/webview_auth_controller.dart';

class WebViewControls extends StatelessWidget {
  const WebViewControls({super.key, required this.controller});

  final WebViewAuthController controller;

  @override
  Widget build(BuildContext context) {
    final isReady = controller.isReady;
    final canNavigate = isReady && !controller.isLoading;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WebView controls',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: isReady
                      ? () => unawaited(controller.openLoginPage())
                      : null,
                  icon: const Icon(Icons.login),
                  label: const Text('Open login page'),
                ),
                OutlinedButton.icon(
                  onPressed: isReady
                      ? () => unawaited(controller.openUsagePagePlaceholder())
                      : null,
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Open usage page placeholder'),
                ),
                OutlinedButton.icon(
                  onPressed: canNavigate
                      ? () => unawaited(controller.reload())
                      : null,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload'),
                ),
                IconButton.outlined(
                  tooltip: 'Back',
                  onPressed: canNavigate && controller.canGoBack
                      ? () => unawaited(controller.goBack())
                      : null,
                  icon: const Icon(Icons.arrow_back),
                ),
                IconButton.outlined(
                  tooltip: 'Forward',
                  onPressed: canNavigate && controller.canGoForward
                      ? () => unawaited(controller.goForward())
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                ),
                OutlinedButton.icon(
                  onPressed: isReady
                      ? () => unawaited(_confirmClearWebViewData(context))
                      : null,
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: const Text('Clear WebView data'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'This only clears this app\'s WebView data where supported. It does not clear your system browser.',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearWebViewData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear WebView data?'),
          content: const Text(
            'This clears this app\'s WebView cache, local storage, and WebView cookies where supported. It does not clear your system browser or local quota history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear WebView data'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await controller.clearWebViewData();
    }
  }
}
