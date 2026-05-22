import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_format.dart';
import '../../../quota/domain/entities/parser_confidence.dart';
import '../../domain/entities/quota_parse_result.dart';
import 'parsed_window_card.dart';

class ParseResultCard extends StatelessWidget {
  const ParseResultCard({super.key, required this.result});

  final QuotaParseResult? result;

  @override
  Widget build(BuildContext context) {
    final parseResult = result;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: parseResult == null
            ? const Text('No parser result yet.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Parse result', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _Field(
                    label: 'Success',
                    value: parseResult.success.toString(),
                  ),
                  _Field(
                    label: 'Confidence',
                    value: parseResult.confidence.label,
                  ),
                  _Field(
                    label: 'Parser version',
                    value: parseResult.parserVersion,
                  ),
                  _Field(
                    label: 'Parsed at',
                    value: formatDateTime(parseResult.parsedAt),
                  ),
                  const SizedBox(height: 8),
                  _TextList(
                    title: 'Matched signals',
                    values: parseResult.matchedSignals,
                    emptyText: 'none',
                  ),
                  _TextList(
                    title: 'Warnings',
                    values: parseResult.warnings,
                    emptyText: 'none',
                  ),
                  _TextList(
                    title: 'Errors',
                    values: parseResult.errors,
                    emptyText: 'none',
                  ),
                  if (parseResult.windows.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...parseResult.windows.map(
                      (window) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ParsedWindowCard(window: window),
                      ),
                    ),
                  ],
                  if (parseResult.credits != null) ...[
                    const SizedBox(height: 8),
                    Text('Credits', style: theme.textTheme.labelLarge),
                    _Field(
                      label: 'Remaining',
                      value:
                          parseResult.credits?.remaining?.toStringAsFixed(2) ??
                          'unknown',
                    ),
                    _Field(
                      label: 'Total',
                      value:
                          parseResult.credits?.total?.toStringAsFixed(2) ??
                          'unknown',
                    ),
                    _Field(
                      label: 'Evidence',
                      value: parseResult.credits?.rawText ?? 'unknown',
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _TextList extends StatelessWidget {
  const _TextList({
    required this.title,
    required this.values,
    required this.emptyText,
  });

  final String title;
  final List<String> values;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          if (values.isEmpty)
            Text(emptyText)
          else
            ...values.map((value) => Text('- $value')),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: Text(
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
