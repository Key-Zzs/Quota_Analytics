import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/date_time_format.dart';
import '../../../parser/presentation/controllers/quota_parser_controller.dart';
import '../../../parser/presentation/widgets/parse_result_card.dart';
import '../../../quota/domain/entities/parser_confidence.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../../quota/domain/entities/quota_source.dart';
import '../controllers/page_text_extraction_controller.dart';
import 'extracted_text_preview.dart';

class ExtractionStatusCard extends StatelessWidget {
  const ExtractionStatusCard({
    super.key,
    required this.controller,
    this.quotaParserController,
    this.onParsedSnapshotSaved,
  });

  final PageTextExtractionController controller;
  final QuotaParserController? quotaParserController;
  final ValueChanged<QuotaSnapshot>? onParsedSnapshotSaved;

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
            const Text(
              'Stage 5 can parse the redacted visible text locally after you tap Parse.',
            ),
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
            if (quotaParserController != null) ...[
              const SizedBox(height: 16),
              _ParserSection(
                extractionController: controller,
                parserController: quotaParserController!,
                onParsedSnapshotSaved: onParsedSnapshotSaved,
              ),
            ],
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

class _ParserSection extends StatelessWidget {
  const _ParserSection({
    required this.extractionController,
    required this.parserController,
    required this.onParsedSnapshotSaved,
  });

  final PageTextExtractionController extractionController;
  final QuotaParserController parserController;
  final ValueChanged<QuotaSnapshot>? onParsedSnapshotSaved;

  @override
  Widget build(BuildContext context) {
    final extraction = extractionController.lastExtraction;
    final hasText = extraction?.hasPreview == true;
    final preview = parserController.previewSnapshot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stage 5 quota parser',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text('Parser input is the current redacted visible text only.'),
        const Text('Automatic refresh remains disabled.'),
        if (!hasText)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Extract page text before parsing.'),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const ValueKey('parse-extracted-text-button'),
              onPressed: hasText && !parserController.isParsing
                  ? () => unawaited(
                      parserController.parseExtractedText(extraction),
                    )
                  : null,
              icon: const Icon(Icons.manage_search),
              label: Text(
                parserController.isParsing
                    ? 'Parsing...'
                    : 'Parse Extracted Text',
              ),
            ),
            OutlinedButton.icon(
              key: const ValueKey('save-parsed-snapshot-button'),
              onPressed: parserController.canSaveParsedSnapshot
                  ? () => unawaited(_confirmSaveParsedSnapshot(context))
                  : null,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                parserController.isSaving
                    ? 'Saving...'
                    : 'Save Parsed Snapshot',
              ),
            ),
            OutlinedButton.icon(
              onPressed: parserController.lastResult == null
                  ? null
                  : parserController.clearParseResult,
              icon: const Icon(Icons.clear),
              label: const Text('Clear parser result'),
            ),
          ],
        ),
        if (parserController.message != null) ...[
          const SizedBox(height: 12),
          Text(parserController.message!),
        ],
        if (parserController.lastError != null) ...[
          const SizedBox(height: 8),
          Text('Last parser error: ${parserController.lastError}'),
        ],
        const SizedBox(height: 12),
        Text(
          'Last parser input length: ${parserController.lastParserInputLength}',
        ),
        if (preview != null) ...[
          const SizedBox(height: 8),
          Text('Snapshot preview source: ${preview.source.label}'),
          Text(
            'Snapshot preview confidence: ${preview.parserConfidence.label}',
          ),
          Text(
            'Snapshot preview captured at: ${formatDateTime(preview.capturedAt)}',
          ),
        ],
        const SizedBox(height: 12),
        ParseResultCard(result: parserController.lastResult),
      ],
    );
  }

  Future<void> _confirmSaveParsedSnapshot(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save parsed snapshot?'),
          content: const Text(
            'This will save the parsed result as a local quota snapshot.',
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

    if (confirmed != true || !context.mounted) {
      return;
    }

    final saved = await parserController.saveParsedSnapshot();
    if (saved != null) {
      onParsedSnapshotSaved?.call(saved);
    }
    if (!context.mounted) {
      return;
    }
    final message = saved == null
        ? 'Parsed snapshot was not saved'
        : 'Parsed snapshot saved locally';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
