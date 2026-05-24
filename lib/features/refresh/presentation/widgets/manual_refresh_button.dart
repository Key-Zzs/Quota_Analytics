import 'package:flutter/material.dart';

class ManualRefreshButton extends StatelessWidget {
  const ManualRefreshButton({
    super.key,
    required this.isBusy,
    required this.onPressed,
  });

  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: const ValueKey('manual-refresh-from-webview-button'),
      onPressed: isBusy ? null : onPressed,
      icon: const Icon(Icons.sync),
      label: Text(
        isBusy
            ? 'Refreshing from WebView...'
            : 'Manual Refresh from Current Page',
      ),
    );
  }
}
