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
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: isReady
                        ? () => unawaited(controller.openLoginPage())
                        : null,
                    icon: const Icon(Icons.login),
                    label: const Text('Open login page'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: isReady
                        ? () => unawaited(controller.openUsagePage())
                        : null,
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Open usage page'),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'Reload',
                    onPressed: canNavigate
                        ? () => unawaited(controller.reload())
                        : null,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'Back',
                    onPressed: canNavigate && controller.canGoBack
                        ? () => unawaited(controller.goBack())
                        : null,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'Forward',
                    onPressed: canNavigate && controller.canGoForward
                        ? () => unawaited(controller.goForward())
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'Clear WebView data',
                    onPressed: isReady
                        ? () => unawaited(_confirmClearWebViewData(context))
                        : null,
                    icon: const Icon(Icons.cleaning_services_outlined),
                  ),
                ],
              ),
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
