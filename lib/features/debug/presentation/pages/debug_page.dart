import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/security/sensitive_data_policy.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../../auth/presentation/controllers/webview_auth_controller.dart';
import '../../../extraction/presentation/controllers/page_text_extraction_controller.dart';
import '../../../extraction/presentation/widgets/extracted_text_preview.dart';
import '../../../parser/presentation/controllers/quota_parser_controller.dart';
import '../../../quota/domain/entities/parser_confidence.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../../quota/domain/entities/quota_source.dart';
import '../../../quota/presentation/controllers/quota_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

class DebugPage extends StatelessWidget {
  const DebugPage({
    super.key,
    required this.controller,
    required this.settingsController,
    required this.webAuthController,
    required this.pageTextExtractionController,
    required this.quotaParserController,
    required this.onClearLocalData,
  });

  final QuotaController controller;
  final SettingsController settingsController;
  final WebViewAuthController webAuthController;
  final PageTextExtractionController pageTextExtractionController;
  final QuotaParserController quotaParserController;
  final Future<void> Function() onClearLocalData;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller,
        settingsController,
        webAuthController,
        pageTextExtractionController,
        quotaParserController,
      ]),
      builder: (context, _) {
        final snapshot = controller.snapshot;
        final persistence = controller.persistenceStatus;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DebugCard(
              title: 'Persistence',
              children: [
                _DebugRow(label: 'Persistence mode', value: persistence.mode),
                _DebugRow(
                  label: 'Storage backend',
                  value: persistence.storageBackend,
                ),
                _DebugRow(
                  label: 'Last snapshot exists',
                  value: persistence.lastSnapshotExists.toString(),
                ),
                _DebugRow(
                  label: 'History count',
                  value: persistence.historyCount.toString(),
                ),
                _DebugRow(
                  label: 'Current interval',
                  value: settingsController.refreshInterval.label,
                ),
                _DebugRow(
                  label: 'Auto refresh enabled',
                  value: settingsController.autoRefreshEnabled.toString(),
                ),
                _DebugRow(
                  label: 'Last load time',
                  value: formatDateTime(persistence.lastLoadTime),
                ),
                _DebugRow(
                  label: 'Last save time',
                  value: formatDateTime(persistence.lastSaveTime),
                ),
                _DebugRow(
                  label: 'Last persistence error',
                  value: persistence.lastError ?? 'none',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: controller.isLoading || settingsController.isSaving
                      ? null
                      : () => unawaited(_confirmClear(context)),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear local data'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DebugCard(
              title: 'Runtime',
              children: [
                _DebugRow(label: 'App mode', value: AppConstants.appMode),
                const _DebugRow(
                  label: 'Current data source',
                  value: 'MockQuotaDataSource + LocalQuotaDataSource',
                ),
                _DebugRow(
                  label: 'Snapshot source',
                  value: snapshot?.source.label ?? 'none',
                ),
                _DebugRow(
                  label: 'Last refresh result',
                  value: controller.lastRefreshResult,
                ),
                _DebugRow(
                  label: 'Last refresh duration',
                  value: formatDuration(controller.lastRefreshDuration),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DebugCard(
              title: 'Stage 3 WebView',
              children: [
                const _DebugRow(
                  label: 'WebView feature enabled',
                  value: 'true',
                ),
                _DebugRow(
                  label: 'Current web auth status',
                  value: webAuthController.authStatus.label,
                ),
                _DebugRow(
                  label: 'Last WebView URL',
                  value: webAuthController.currentUrl,
                ),
                _DebugRow(
                  label: 'Last WebView error',
                  value: webAuthController.lastError ?? 'none',
                ),
                const SizedBox(height: 8),
                const Text('Safety status'),
                Text(
                  'Cookie reading ${_disabledLabel(SensitiveDataPolicy.cookieReadingEnabled)}',
                ),
                Text(
                  'Token reading ${_disabledLabel(SensitiveDataPolicy.tokenReadingEnabled)}',
                ),
                Text(
                  'localStorage reading ${_disabledLabel(SensitiveDataPolicy.localStorageReadingEnabled)}',
                ),
                Text(
                  'sessionStorage reading ${_disabledLabel(SensitiveDataPolicy.sessionStorageReadingEnabled)}',
                ),
                Text(
                  'HTML extraction ${_disabledLabel(SensitiveDataPolicy.htmlExtractionEnabled)}',
                ),
                Text(
                  'Quota parsing ${_disabledLabel(SensitiveDataPolicy.quotaParsingEnabled)}',
                ),
                Text(
                  'Background refresh ${_disabledLabel(SensitiveDataPolicy.backgroundRefreshEnabled)}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DebugCard(
              title: 'Stage 4 Text Extraction',
              children: [
                const _DebugRow(
                  label: 'Text extraction enabled',
                  value: 'true',
                ),
                _DebugRow(
                  label: 'Extracted text cache exists',
                  value: pageTextExtractionController.hasCachedText.toString(),
                ),
                _DebugRow(
                  label: 'Last extraction time',
                  value: formatDateTime(
                    pageTextExtractionController.lastExtraction?.extractedAt,
                  ),
                ),
                _DebugRow(
                  label: 'Last extraction URL',
                  value:
                      pageTextExtractionController
                          .lastExtraction
                          ?.sanitizedUrl ??
                      'none',
                ),
                _DebugRow(
                  label: 'Last extraction safety status',
                  value:
                      pageTextExtractionController
                          .lastExtraction
                          ?.safetyStatus
                          .label ??
                      'none',
                ),
                _DebugRow(
                  label: 'Last extraction error',
                  value:
                      pageTextExtractionController
                          .lastExtraction
                          ?.errorMessage ??
                      pageTextExtractionController.lastError ??
                      'none',
                ),
                _DebugRow(
                  label: 'Original length',
                  value:
                      pageTextExtractionController
                          .lastExtraction
                          ?.originalLength
                          .toString() ??
                      '0',
                ),
                _DebugRow(
                  label: 'Redacted length',
                  value:
                      pageTextExtractionController
                          .lastExtraction
                          ?.redactedLength
                          .toString() ??
                      '0',
                ),
                _DebugRow(
                  label: 'Truncated',
                  value:
                      pageTextExtractionController.lastExtraction?.truncated
                          .toString() ??
                      'false',
                ),
                _DebugRow(
                  label: 'Redaction counts',
                  value: _redactionCounts(pageTextExtractionController),
                ),
                const SizedBox(height: 8),
                const Text('Last extracted text preview'),
                const SizedBox(height: 8),
                ExtractedTextPreview(
                  extraction: pageTextExtractionController.lastExtraction,
                ),
                const SizedBox(height: 8),
                const Text('Cookie reading disabled'),
                const Text('Token reading disabled'),
                const Text('localStorage reading disabled'),
                const Text('sessionStorage reading disabled'),
                const Text('HTML extraction disabled'),
                const Text('Quota parsing enabled'),
                const Text('Background refresh disabled'),
              ],
            ),
            const SizedBox(height: 12),
            _DebugCard(
              title: 'Stage 5 Quota Parser',
              children: [
                const _DebugRow(label: 'Quota parser enabled', value: 'true'),
                const _DebugRow(label: 'Automatic refresh', value: 'disabled'),
                _DebugRow(
                  label: 'Last parser input length',
                  value: quotaParserController.lastParserInputLength.toString(),
                ),
                _DebugRow(
                  label: 'Last parser confidence',
                  value:
                      quotaParserController.lastResult?.confidence.label ??
                      ParserConfidence.notApplicable.label,
                ),
                _DebugRow(
                  label: 'Parser version',
                  value:
                      quotaParserController.lastResult?.parserVersion ??
                      'regex-quota-parser-v1',
                ),
                _DebugRow(
                  label: 'Last parser warnings',
                  value:
                      quotaParserController.lastResult?.warnings.join(' | ') ??
                      'none',
                ),
                _DebugRow(
                  label: 'Last parser errors',
                  value:
                      quotaParserController.lastResult?.errors.join(' | ') ??
                      quotaParserController.lastError ??
                      'none',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DebugCard(
              title: 'Recent snapshots',
              children: [
                if (controller.history.isEmpty)
                  const Text('No persisted history yet.')
                else
                  ...controller.history
                      .take(10)
                      .map((snapshot) => _SnapshotSummary(snapshot: snapshot)),
              ],
            ),
            const SizedBox(height: 12),
            _DebugCard(
              title: 'Current QuotaSnapshot',
              children: [
                SelectableText(
                  snapshot?.toDebugText() ?? 'No snapshot loaded.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _DebugCard(
              title: 'Safety notice',
              children: [
                Text('WebView login container only'),
                Text('No token access'),
                Text('No cookie reading'),
                Text('No localStorage or sessionStorage reading'),
                Text('Manual visible text extraction only'),
                Text('Local quota parsing from redacted text only'),
                Text('No background refresh'),
                SizedBox(height: 8),
                Text(AppConstants.stageNotice),
              ],
            ),
          ],
        );
      },
    );
  }

  static String _disabledLabel(bool enabled) {
    return enabled ? 'enabled' : 'disabled';
  }

  static String _redactionCounts(PageTextExtractionController controller) {
    final extraction = controller.lastExtraction;
    if (extraction == null) {
      return 'email 0, token 0, apiKey 0, secret 0';
    }
    return 'email ${extraction.redactedEmailCount}, token ${extraction.redactedTokenCount}, apiKey ${extraction.redactedApiKeyCount}, secret ${extraction.redactedSecretCount}';
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear local data?'),
          content: const Text(
            'This removes only this app\'s saved mock quota snapshots, settings, and redacted extracted text preview.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await onClearLocalData();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Local data cleared')));
  }
}

class _SnapshotSummary extends StatelessWidget {
  const _SnapshotSummary({required this.snapshot});

  final QuotaSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatDateTime(snapshot.capturedAt),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text('Source: ${snapshot.source.label}'),
              Text(
                '5-hour: ${_windowLine(snapshot.fiveHourWindow.remaining, snapshot.fiveHourWindow.used, snapshot.fiveHourWindow.limit)}',
              ),
              Text(
                'Weekly: ${_windowLine(snapshot.weeklyWindow.remaining, snapshot.weeklyWindow.used, snapshot.weeklyWindow.limit)}',
              ),
              Text(
                'Credits remaining: ${snapshot.creditsRemaining?.toStringAsFixed(2) ?? 'unknown'}',
              ),
              Text('Parser confidence: ${snapshot.parserConfidence.label}'),
            ],
          ),
        ),
      ),
    );
  }

  String _windowLine(int? remaining, int? used, int? limit) {
    return 'remaining ${remaining ?? 'unknown'} / used ${used ?? 'unknown'} / limit ${limit ?? 'unknown'}';
  }
}

class _DebugCard extends StatelessWidget {
  const _DebugCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label)),
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
