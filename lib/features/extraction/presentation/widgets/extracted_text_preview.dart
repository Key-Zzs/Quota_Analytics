import 'package:flutter/material.dart';

import '../../domain/entities/extracted_page_text.dart';

class ExtractedTextPreview extends StatelessWidget {
  const ExtractedTextPreview({super.key, required this.extraction});

  final ExtractedPageText? extraction;

  @override
  Widget build(BuildContext context) {
    final value = extraction?.redactedTextPreview.trim();
    final text = value == null || value.isEmpty
        ? 'No redacted preview extracted yet.'
        : value;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SelectableText(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ),
      ),
    );
  }
}
