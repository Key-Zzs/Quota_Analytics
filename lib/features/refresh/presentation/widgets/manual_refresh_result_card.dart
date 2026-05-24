import 'dart:async';

import 'package:flutter/material.dart';

import '../../../parser/presentation/widgets/parsed_window_card.dart';
import '../../../quota/domain/entities/parser_confidence.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../../quota/domain/entities/quota_source.dart';
import '../controllers/manual_refresh_controller.dart';
import 'save_snapshot_confirmation.dart';

class ManualRefreshResultCard extends StatelessWidget {
  const ManualRefreshResultCard({
    super.key,
    required this.controller,
    this.onSnapshotSaved,
  });

  final ManualRefreshController controller;
  final ValueChanged<QuotaSnapshot>? onSnapshotSaved;

  @override
  Widget build(BuildContext context) {
    final result = controller.lastResult;
    final parseResult = result.parseResult;
    final candidate = result.snapshotCandidate;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manual refresh result',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pipeline: safe URL check, visible text extraction, local redaction, local parser, then user-confirmed local save.',
            ),
            const Text(
              'No cookies, tokens, localStorage, sessionStorage, HTML, network responses, or uploads are used.',
            ),
            if (controller.message != null) ...[
              const SizedBox(height: 12),
              Text(controller.message!),
            ],
            if (controller.lastError != null) ...[
              const SizedBox(height: 8),
              Text('Last manual refresh error: ${controller.lastError}'),
            ],
            if (result.parserConfidence == ParserConfidence.low) ...[
              const SizedBox(height: 12),
              const Text('Low confidence results are not saved.'),
            ],
            if (candidate != null) ...[
              const SizedBox(height: 12),
              Text(
                'Snapshot candidate',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text('Source: ${candidate.source.label}'),
              Text('Confidence: ${candidate.parserConfidence.label}'),
              Text('5-hour window: ${candidate.fiveHourWindow.label}'),
              Text('Weekly window: ${candidate.weeklyWindow.label}'),
              Text(
                'Credits remaining: ${candidate.creditsRemaining?.toStringAsFixed(2) ?? 'unknown'}',
              ),
            ],
            if (parseResult != null) ...[
              const SizedBox(height: 12),
              Text(
                'Matched signals: ${parseResult.matchedSignals.isEmpty ? 'none' : parseResult.matchedSignals.join(', ')}',
              ),
              if (parseResult.windows.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...parseResult.windows.map(
                  (window) => ParsedWindowCard(window: window),
                ),
              ],
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const ValueKey('manual-save-parsed-snapshot-button'),
                  onPressed: controller.canSaveCandidate
                      ? () => unawaited(_confirmAndSave(context))
                      : null,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    controller.isSaving ? 'Saving...' : 'Save Parsed Snapshot',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndSave(BuildContext context) async {
    final confirmed = await showSaveSnapshotConfirmation(
      context,
      controller.lastResult,
    );
    if (!context.mounted) {
      return;
    }
    if (!confirmed) {
      controller.markSaveCancelled();
      return;
    }

    final saved = await controller.saveSnapshotCandidate();
    if (saved != null) {
      onSnapshotSaved?.call(saved);
    }
    if (!context.mounted) {
      return;
    }
    final message = saved == null
        ? 'Manual refresh snapshot was not saved'
        : 'Manual refresh snapshot saved locally';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
