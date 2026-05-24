import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extracted_page_text.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_safety_status.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_source.dart';
import 'package:quota_analytics/features/extraction/domain/repositories/page_text_extraction_repository.dart';
import 'package:quota_analytics/features/parser/data/mappers/parse_result_to_quota_snapshot_mapper.dart';
import 'package:quota_analytics/features/parser/domain/entities/parsed_quota_window.dart';
import 'package:quota_analytics/features/parser/domain/entities/quota_parse_result.dart';
import 'package:quota_analytics/features/parser/domain/entities/quota_window_type.dart';
import 'package:quota_analytics/features/parser/domain/repositories/quota_parser_repository.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';
import 'package:quota_analytics/features/quota/domain/entities/parser_confidence.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_persistence_status.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_snapshot.dart';
import 'package:quota_analytics/features/quota/domain/repositories/quota_repository.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_policy.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_result.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_status.dart';
import 'package:quota_analytics/features/refresh/domain/repositories/manual_refresh_repository.dart';
import 'package:quota_analytics/features/refresh/domain/usecases/refresh_quota_from_webview.dart';
import 'package:quota_analytics/features/refresh/domain/usecases/save_manual_refresh_snapshot.dart';
import 'package:quota_analytics/features/refresh/presentation/controllers/manual_refresh_controller.dart';
import 'package:quota_analytics/features/refresh/presentation/widgets/manual_refresh_result_card.dart';
import 'package:quota_analytics/features/refresh/presentation/widgets/manual_refresh_status_card.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1, 12);

  testWidgets('ManualRefreshStatusCard displays refresh states', (
    tester,
  ) async {
    for (final status in [
      ManualRefreshStatus.checkingPage,
      ManualRefreshStatus.extractingText,
      ManualRefreshStatus.parsing,
      ManualRefreshStatus.saved,
    ]) {
      final controller = _controller(_result(now, status: status));
      await controller.loadLastResult();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ManualRefreshStatusCard(controller: controller)),
        ),
      );

      expect(find.text(status.label), findsOneWidget);
    }
  });

  testWidgets('low confidence result shows not saved prompt', (tester) async {
    final controller = _controller(
      _result(
        now,
        status: ManualRefreshStatus.lowConfidence,
        confidence: ParserConfidence.low,
        withCandidate: false,
      ),
    );
    await controller.loadLastResult();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [ManualRefreshResultCard(controller: controller)],
          ),
        ),
      ),
    );

    expect(find.text('Low confidence results are not saved.'), findsOneWidget);
  });

  testWidgets('Save Parsed Snapshot button is enabled for high confidence', (
    tester,
  ) async {
    final controller = _controller(
      _result(now, confidence: ParserConfidence.high),
    );
    await controller.loadLastResult();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [ManualRefreshResultCard(controller: controller)],
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('manual-save-parsed-snapshot-button')),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('Save Parsed Snapshot button is enabled for medium confidence', (
    tester,
  ) async {
    final controller = _controller(
      _result(now, confidence: ParserConfidence.medium),
    );
    await controller.loadLastResult();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [ManualRefreshResultCard(controller: controller)],
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('manual-save-parsed-snapshot-button')),
    );
    expect(button.onPressed, isNotNull);
  });
}

ManualRefreshController _controller(ManualRefreshResult initialResult) {
  final now = initialResult.startedAt;
  final manualRepository = _FakeManualRefreshRepository(initialResult);
  final quotaRepository = _FakeQuotaRepository();
  final saveUseCase = SaveManualRefreshSnapshot(
    quotaRepository: quotaRepository,
    manualRefreshRepository: manualRepository,
    clock: FixedClock(now),
  );
  return ManualRefreshController(
    refreshQuotaFromWebView: RefreshQuotaFromWebView(
      extractionRepository: _FakeExtractionRepository(),
      parserRepository: _FakeParserRepository(_parseResult(now)),
      mapper: const ParseResultToQuotaSnapshotMapper(),
      manualRefreshRepository: manualRepository,
      saveManualRefreshSnapshot: saveUseCase,
      clock: FixedClock(now),
    ),
    saveManualRefreshSnapshot: saveUseCase,
    manualRefreshRepository: manualRepository,
    policyProvider: ManualRefreshPolicy.defaults,
    clock: FixedClock(now),
  );
}

ManualRefreshResult _result(
  DateTime now, {
  ManualRefreshStatus status = ManualRefreshStatus.awaitingUserConfirmation,
  ParserConfidence confidence = ParserConfidence.high,
  bool withCandidate = true,
}) {
  final snapshot = QuotaSnapshotModel.mock(capturedAt: now, variant: 1);
  final parseResult = _parseResult(now, confidence: confidence);
  return ManualRefreshResult(
    status: status,
    safetyStatus: ExtractionSafetyStatus.allowed,
    parserConfidence: confidence,
    extractedPageText: _extraction(now),
    parseResult: parseResult,
    snapshotCandidate: withCandidate ? snapshot : null,
    redactionSummary: null,
    warnings: const [],
    errors: const [],
    startedAt: now,
    finishedAt: now,
    savedSnapshotId: status == ManualRefreshStatus.saved ? snapshot.id : null,
  );
}

ExtractedPageText _extraction(DateTime now) {
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
    extractedAt: now,
    source: ExtractionSource.webViewManual,
    safetyStatus: ExtractionSafetyStatus.allowed,
  );
}

QuotaParseResult _parseResult(
  DateTime now, {
  ParserConfidence confidence = ParserConfidence.high,
}) {
  return QuotaParseResult(
    success: confidence != ParserConfidence.failed,
    confidence: confidence,
    windows: confidence == ParserConfidence.low
        ? const []
        : const [
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
    warnings: const [],
    errors: const [],
    parsedAt: now,
    parserVersion: 'fake-parser',
  );
}

class _FakeExtractionRepository implements PageTextExtractionRepository {
  @override
  void attachPageTextReader(CurrentPageTextReader reader) {}

  @override
  Future<void> clearExtractedPageText() async {}

  @override
  Future<ExtractedPageText> extractCurrentPageText() async {
    return _extraction(DateTime.utc(2026, 1, 1, 12));
  }

  @override
  Future<ExtractedPageText?> getLastExtractedPageText() async {
    return null;
  }
}

class _FakeParserRepository implements QuotaParserRepository {
  const _FakeParserRepository(this.result);

  final QuotaParseResult result;

  @override
  QuotaParseResult parse(String text, {DateTime? now}) {
    return result;
  }
}

class _FakeManualRefreshRepository implements ManualRefreshRepository {
  _FakeManualRefreshRepository(this.last);

  ManualRefreshResult? last;

  @override
  Future<void> clearLastResult() async {
    last = null;
  }

  @override
  Future<ManualRefreshResult?> getLastResult() async {
    return last;
  }

  @override
  Future<ManualRefreshResult> saveLastResult(ManualRefreshResult result) async {
    last = result;
    return result;
  }
}

class _FakeQuotaRepository implements QuotaRepository {
  QuotaSnapshot? saved;

  @override
  Future<void> clearLocalQuotaData() async {}

  @override
  Future<List<QuotaSnapshot>> getHistory() async {
    return saved == null ? const [] : [saved!];
  }

  @override
  Future<QuotaSnapshot> getLatestSnapshot() async {
    return saved!;
  }

  @override
  Future<QuotaPersistenceStatus> getPersistenceStatus() async {
    return QuotaPersistenceStatus.mockOnly();
  }

  @override
  Future<QuotaSnapshot> refreshSnapshot() async {
    return saved!;
  }

  @override
  Future<QuotaSnapshot> saveSnapshot(QuotaSnapshot snapshot) async {
    saved = snapshot;
    return snapshot;
  }
}
