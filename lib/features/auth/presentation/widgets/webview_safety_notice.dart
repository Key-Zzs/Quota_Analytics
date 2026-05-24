import 'package:flutter/material.dart';

class WebViewSafetyNotice extends StatelessWidget {
  const WebViewSafetyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        key: const ValueKey('webview-safety-notice'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        initiallyExpanded: false,
        leading: Icon(
          Icons.verified_user_outlined,
          color: colorScheme.onSecondaryContainer,
        ),
        title: Text(
          'Stage 7: foreground only, visible text only',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          'No cookies, tokens, storage, HTML, or uploads.',
          style: TextStyle(color: colorScheme.onSecondaryContainer),
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are logging in through the official website inside a WebView.',
                style: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
              Text(
                'This app does not ask for or store your password.',
                style: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
              Text(
                'This app does not read cookies or tokens.',
                style: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
              Text(
                'No cookies, tokens, localStorage, sessionStorage, or HTML are accessed.',
                style: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
              Text(
                'Quota parsing runs locally only after text has been redacted.',
                style: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
              Text(
                'Reload-before-refresh is foreground only and never runs in Android background tasks.',
                style: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
              Text(
                'Extracted text is redacted and kept local for debugging.',
                style: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
              const SizedBox(height: 8),
              Text(
                'Unofficial personal tool. Official website is loaded inside WebView.',
                style: TextStyle(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
