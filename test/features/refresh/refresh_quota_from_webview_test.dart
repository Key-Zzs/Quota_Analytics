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
import 'package:quota_analytics/features/quota/domain/entities/parser_confidence.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_persistence_status.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_snapshot.dart';
import 'package:quota_analytics/features/quota/domain/repositories/quota_repository.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_page_state.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_policy.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_result.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_status.dart';
import 'package:quota_analytics/features/refresh/domain/repositories/manual_refresh_repository.dart';
import 'package:quota_analytics/features/refresh/domain/usecases/refresh_quota_from_webview.dart';
import 'package:quota_analytics/features/refresh/domain/usecases/save_manual_refresh_snapshot.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1, 12);

  test(
    'success path creates candidate and waits for confirmation by default',
    () async {
      final quotaRepository = _FakeQuotaRepository();
      final manualRepository = _FakeManualRefreshRepository();
      final saveUseCase = _saveUseCase(quotaRepository, manualRepository, now);
      final useCase = _useCase(
        extractionRepository: _FakeExtractionRepository(
          result: _extraction(now, '5-hour window Used 10 of 50'),
        ),
        parserRepository: _FakeParserRepository(_parseResult(now)),
        manualRepository: manualRepository,
        saveUseCase: saveUseCase,
        now: now,
      );

      final result = await useCase(
        pageState: _safePage(),
        policy: ManualRefreshPolicy.defaults(),
      );

      expect(result.status, ManualRefreshStatus.awaitingUserConfirmation);
      expect(result.snapshotCandidate, isNotNull);
      expect(result.parserConfidence, ParserConfidence.high);
      expect(quotaRepository.saved, isNull);
      expect(manualRepository.last, result);

      final saved = await saveUseCase(
        result,
        policy: ManualRefreshPolicy.defaults(),
      );
      expect(saved.status, ManualRefreshStatus.saved);
      expect(quotaRepository.saved?.source, saved.snapshotCandidate?.source);
    },
  );

  test('non-https URL is blocked before extraction', () async {
    final extractionRepository = _FakeExtractionRepository(
      result: _extraction(now, 'unused'),
    );
    final result =
        await _defaultUseCase(
          extractionRepository: extractionRepository,
          parserRepository: _FakeParserRepository(_parseResult(now)),
          now: now,
        )(
          pageState: const ManualRefreshPageState(
            currentUrl: 'http://chatgpt.com/usage',
            pageTitle: 'Usage',
            isLoading: false,
            isReady: true,
          ),
          policy: ManualRefreshPolicy.defaults(),
        );

    expect(result.status, ManualRefreshStatus.blocked);
    expect(result.safetyStatus, ExtractionSafetyStatus.blockedNonHttps);
    expect(extractionRepository.extractCalls, 0);
  });

  test('unknown host is blocked before extraction', () async {
    final extractionRepository = _FakeExtractionRepository(
      result: _extraction(now, 'unused'),
    );
    final result =
        await _defaultUseCase(
          extractionRepository: extractionRepository,
          parserRepository: _FakeParserRepository(_parseResult(now)),
          now: now,
        )(
          pageState: const ManualRefreshPageState(
            currentUrl: 'https://example.com/usage',
            pageTitle: 'Usage',
            isLoading: false,
            isReady: true,
          ),
          policy: ManualRefreshPolicy.defaults(),
        );

    expect(result.status, ManualRefreshStatus.blocked);
    expect(result.safetyStatus, ExtractionSafetyStatus.blockedUnknownHost);
    expect(extractionRepository.extractCalls, 0);
  });

  test('extraction failure returns extractionFailed', () async {
    final result = await _defaultUseCase(
      extractionRepository: _FakeExtractionRepository(
        result: _extraction(
          now,
          '',
          safetyStatus: ExtractionSafetyStatus.failed,
          errorMessage: 'JS execution failed.',
        ),
      ),
      parserRepository: _FakeParserRepository(_parseResult(now)),
      now: now,
    )(pageState: _safePage(), policy: ManualRefreshPolicy.defaults());

    expect(result.status, ManualRefreshStatus.extractionFailed);
    expect(result.errors.single, contains('JS execution failed'));
  });

  test('parser failed returns parseFailed and does not save', () async {
    final quotaRepository = _FakeQuotaRepository();
    final result = await _defaultUseCase(
      extractionRepository: _FakeExtractionRepository(
        result: _extraction(now, 'ordinary page text'),
      ),
      parserRepository: _FakeParserRepository(
        _parseResult(
          now,
          success: false,
          confidence: ParserConfidence.failed,
          windows: const [],
        ),
      ),
      quotaRepository: quotaRepository,
      now: now,
    )(pageState: _safePage(), policy: ManualRefreshPolicy.defaults());

    expect(result.status, ManualRefreshStatus.parseFailed);
    expect(result.snapshotCandidate, isNull);
    expect(quotaRepository.saved, isNull);
  });

  test('low confidence returns lowConfidence and does not save', () async {
    final quotaRepository = _FakeQuotaRepository();
    final result = await _defaultUseCase(
      extractionRepository: _FakeExtractionRepository(
        result: _extraction(now, 'quota mentioned'),
      ),
      parserRepository: _FakeParserRepository(
        _parseResult(now, confidence: ParserConfidence.low, windows: const []),
      ),
      quotaRepository: quotaRepository,
      now: now,
    )(pageState: _safePage(), policy: ManualRefreshPolicy.defaults());

    expect(result.status, ManualRefreshStatus.lowConfidence);
    expect(result.snapshotCandidate, isNull);
    expect(quotaRepository.saved, isNull);
  });

  test('high confidence auto-save policy saves automatically', () async {
    final quotaRepository = _FakeQuotaRepository();
    final result =
        await _defaultUseCase(
          extractionRepository: _FakeExtractionRepository(
            result: _extraction(now, '5-hour window Used 10 of 50'),
          ),
          parserRepository: _FakeParserRepository(_parseResult(now)),
          quotaRepository: quotaRepository,
          now: now,
        )(
          pageState: _safePage(),
          policy: ManualRefreshPolicy.defaults().copyWith(
            autoSaveHighConfidence: true,
          ),
        );

    expect(result.status, ManualRefreshStatus.saved);
    expect(quotaRepository.saved, isNotNull);
    expect(result.savedSnapshotId, quotaRepository.saved?.id);
  });
}

RefreshQuotaFromWebView _defaultUseCase({
  required _FakeExtractionRepository extractionRepository,
  required _FakeParserRepository parserRepository,
  _FakeQuotaRepository? quotaRepository,
  required DateTime now,
}) {
  final manualRepository = _FakeManualRefreshRepository();
  final saveUseCase = _saveUseCase(
    quotaRepository ?? _FakeQuotaRepository(),
    manualRepository,
    now,
  );
  return _useCase(
    extractionRepository: extractionRepository,
    parserRepository: parserRepository,
    manualRepository: manualRepository,
    saveUseCase: saveUseCase,
    now: now,
  );
}

RefreshQuotaFromWebView _useCase({
  required _FakeExtractionRepository extractionRepository,
  required _FakeParserRepository parserRepository,
  required _FakeManualRefreshRepository manualRepository,
  required SaveManualRefreshSnapshot saveUseCase,
  required DateTime now,
}) {
  return RefreshQuotaFromWebView(
    extractionRepository: extractionRepository,
    parserRepository: parserRepository,
    mapper: const ParseResultToQuotaSnapshotMapper(),
    manualRefreshRepository: manualRepository,
    saveManualRefreshSnapshot: saveUseCase,
    clock: FixedClock(now),
  );
}

SaveManualRefreshSnapshot _saveUseCase(
  _FakeQuotaRepository quotaRepository,
  _FakeManualRefreshRepository manualRepository,
  DateTime now,
) {
  return SaveManualRefreshSnapshot(
    quotaRepository: quotaRepository,
    manualRefreshRepository: manualRepository,
    clock: FixedClock(now),
  );
}

ManualRefreshPageState _safePage() {
  return const ManualRefreshPageState(
    currentUrl: 'https://chatgpt.com/usage',
    pageTitle: 'Usage',
    isLoading: false,
    isReady: true,
  );
}

ExtractedPageText _extraction(
  DateTime extractedAt,
  String text, {
  ExtractionSafetyStatus safetyStatus = ExtractionSafetyStatus.allowed,
  String? errorMessage,
}) {
  return ExtractedPageText(
    id: 'manual-webview-1',
    sanitizedUrl: 'https://chatgpt.com/usage',
    pageTitle: 'Usage',
    redactedTextPreview: text,
    originalLength: text.length,
    redactedLength: text.length,
    redactedEmailCount: 0,
    redactedTokenCount: 0,
    redactedApiKeyCount: 0,
    redactedSecretCount: 0,
    truncated: false,
    extractedAt: extractedAt,
    source: ExtractionSource.webViewManual,
    safetyStatus: safetyStatus,
    errorMessage: errorMessage,
  );
}

QuotaParseResult _parseResult(
  DateTime parsedAt, {
  bool success = true,
  ParserConfidence confidence = ParserConfidence.high,
  List<ParsedQuotaWindow> windows = const [
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
}) {
  return QuotaParseResult(
    success: success,
    confidence: confidence,
    windows: windows,
    credits: null,
    matchedSignals: windows.isEmpty ? const [] : const ['5-hour window'],
    warnings: const [],
    errors: success ? const [] : const ['not enough quota signals'],
    parsedAt: parsedAt,
    parserVersion: 'fake-parser',
  );
}

class _FakeExtractionRepository implements PageTextExtractionRepository {
  _FakeExtractionRepository({required this.result});

  final ExtractedPageText result;
  int extractCalls = 0;

  @override
  void attachPageTextReader(CurrentPageTextReader reader) {}

  @override
  Future<void> clearExtractedPageText() async {}

  @override
  Future<ExtractedPageText> extractCurrentPageText() async {
    extractCalls += 1;
    return result;
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
