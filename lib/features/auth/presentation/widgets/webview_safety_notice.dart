import 'package:flutter/material.dart';

class WebViewSafetyNotice extends StatelessWidget {
  const WebViewSafetyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Stage 5: local parser for redacted visible text',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
      ),
    );
  }
}
