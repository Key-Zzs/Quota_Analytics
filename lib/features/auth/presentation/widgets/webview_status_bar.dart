import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_format.dart';
import '../controllers/webview_auth_controller.dart';

class WebViewStatusBar extends StatelessWidget {
  const WebViewStatusBar({super.key, required this.controller});

  final WebViewAuthController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WebView status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _StatusRow(label: 'Current URL', value: controller.currentUrl),
            _StatusRow(label: 'Page title', value: controller.pageTitle),
            _StatusRow(
              label: 'Loading progress',
              value: '${controller.loadingProgress}%',
            ),
            _StatusRow(
              label: 'Last navigation time',
              value: formatDateTime(controller.lastNavigationTime),
            ),
            _StatusRow(
              label: 'Last error',
              value: controller.lastError ?? 'none',
            ),
            _StatusRow(
              label: 'Auth status',
              value: controller.authStatus.label,
            ),
            const SizedBox(height: 8),
            Text(
              'Login status is inferred from navigation only and may be inaccurate.',
              style: Theme.of(context).textTheme.bodySmall,
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
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: SelectableText(
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
