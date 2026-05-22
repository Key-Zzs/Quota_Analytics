import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/date_time_format.dart';
import '../controllers/page_text_extraction_controller.dart';
import 'extracted_text_preview.dart';

class ExtractionStatusCard extends StatelessWidget {
  const ExtractionStatusCard({super.key, required this.controller});

  final PageTextExtractionController controller;

  @override
  Widget build(BuildContext context) {
    final extraction = controller.lastExtraction;
    final hasPreview = extraction?.hasPreview == true;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stage 4 text extraction',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Stage 4 extracts only visible page text after you tap the button.',
            ),
            const Text(
              'No cookies, tokens, localStorage, sessionStorage, or HTML are accessed.',
            ),
            const Text('Quota parsing is not implemented in this stage.'),
            const Text(
              'Extracted text is redacted and kept local for debugging.',
            ),
            const Text(
              'This project is unofficial and not affiliated with OpenAI, ChatGPT, or Codex.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: controller.isExtracting
                      ? null
                      : () => unawaited(controller.extractCurrentPageText()),
                  icon: const Icon(Icons.text_snippet_outlined),
                  label: Text(
                    controller.isExtracting
                        ? 'Extracting...'
                        : 'Extract Page Text',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: hasPreview
                      ? () => unawaited(_copyRedactedPreview(context))
                      : null,
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copy redacted preview'),
                ),
                OutlinedButton.icon(
                  onPressed: extraction == null
                      ? null
                      : () => unawaited(controller.clearExtractedPageText()),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear extracted preview'),
                ),
              ],
            ),
            if (controller.message != null) ...[
              const SizedBox(height: 12),
              Text(controller.message!),
            ],
            if (controller.lastError != null) ...[
              const SizedBox(height: 8),
              Text('Last extraction error: ${controller.lastError}'),
            ],
            const SizedBox(height: 12),
            Text(
              'Last extraction time: ${formatDateTime(extraction?.extractedAt)}',
            ),
            Text('Last extraction URL: ${extraction?.sanitizedUrl ?? 'none'}'),
            Text(
              'Last extraction safety status: ${extraction?.safetyStatus.label ?? 'none'}',
            ),
            Text('Original length: ${extraction?.originalLength ?? 0}'),
            Text('Redacted length: ${extraction?.redactedLength ?? 0}'),
            Text('Truncated: ${extraction?.truncated ?? false}'),
            Text(
              'Redaction counts: email ${extraction?.redactedEmailCount ?? 0}, token ${extraction?.redactedTokenCount ?? 0}, apiKey ${extraction?.redactedApiKeyCount ?? 0}, secret ${extraction?.redactedSecretCount ?? 0}',
            ),
            const SizedBox(height: 12),
            const Text('Last extracted text preview'),
            const SizedBox(height: 8),
            ExtractedTextPreview(extraction: extraction),
          ],
        ),
      ),
    );
  }

  Future<void> _copyRedactedPreview(BuildContext context) async {
    final preview = controller.lastExtraction?.redactedTextPreview;
    if (preview == null || preview.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: preview));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Redacted preview copied')));
  }
}
