import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/security/text_redactor.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extracted_page_text.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_safety_status.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_source.dart';
import 'package:quota_analytics/features/parser/domain/entities/parsed_quota_window.dart';
import 'package:quota_analytics/features/parser/domain/entities/quota_parse_result.dart';
import 'package:quota_analytics/features/parser/domain/entities/quota_window_type.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';
import 'package:quota_analytics/features/quota/domain/entities/parser_confidence.dart';
import 'package:quota_analytics/features/refresh/data/models/manual_refresh_result_model.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_result.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_status.dart';

void main() {
  test('JSON round trip keeps duration warnings and errors', () {
    final startedAt = DateTime.utc(2026, 1, 1, 12);
    final finishedAt = startedAt.add(const Duration(seconds: 3));
    final snapshot = QuotaSnapshotModel.mock(
      capturedAt: finishedAt,
      variant: 1,
    );
    final result = ManualRefreshResult(
      status: ManualRefreshStatus.awaitingUserConfirmation,
      safetyStatus: ExtractionSafetyStatus.allowed,
      parserConfidence: ParserConfidence.high,
      extractedPageText: _extraction(startedAt),
      parseResult: _parseResult(finishedAt),
      snapshotCandidate: snapshot,
      redactionSummary: const RedactionSummary(
        originalLength: 120,
        redactedLength: 100,
        redactedEmailCount: 1,
        redactedTokenCount: 0,
        redactedApiKeyCount: 0,
        redactedSecretCount: 0,
        truncated: false,
      ),
      warnings: const ['review before saving'],
      errors: const ['sample error'],
      startedAt: startedAt,
      finishedAt: finishedAt,
      savedSnapshotId: null,
    );

    final json = ManualRefreshResultModel.fromEntity(result).toJson();
    final loaded = ManualRefreshResultModel.fromJson(json);

    expect(loaded.status, ManualRefreshStatus.awaitingUserConfirmation);
    expect(loaded.duration, const Duration(seconds: 3));
    expect(loaded.warnings, ['review before saving']);
    expect(loaded.errors, ['sample error']);
    expect(loaded.redactionSummary?.redactedEmailCount, 1);
    expect(loaded.snapshotCandidate?.id, snapshot.id);
    expect(loaded.parseResult?.windows.single.type, QuotaWindowType.fiveHour);
  });
}

ExtractedPageText _extraction(DateTime extractedAt) {
  return ExtractedPageText(
    id: 'manual-webview-1',
    sanitizedUrl: 'https://chatgpt.com/usage',
    pageTitle: 'Usage',
    redactedTextPreview: '5-hour window Used 10 of 50',
    originalLength: 26,
    redactedLength: 26,
    redactedEmailCount: 0,
    redactedTokenCount: 0,
    redactedApiKeyCount: 0,
    redactedSecretCount: 0,
    truncated: false,
    extractedAt: extractedAt,
    source: ExtractionSource.webViewManual,
    safetyStatus: ExtractionSafetyStatus.allowed,
  );
}

QuotaParseResult _parseResult(DateTime parsedAt) {
  return QuotaParseResult(
    success: true,
    confidence: ParserConfidence.high,
    windows: const [
      ParsedQuotaWindow(
        type: QuotaWindowType.fiveHour,
        used: 10,
        limit: 50,
        remaining: 40,
        remainingRatio: 0.8,
        resetAt: null,
        resetText: null,
        evidenceLabels: ['5-hour window'],
      ),
    ],
    credits: null,
    matchedSignals: const ['5-hour window'],
    warnings: const ['review before saving'],
    errors: const [],
    parsedAt: parsedAt,
    parserVersion: 'test-parser',
  );
}
