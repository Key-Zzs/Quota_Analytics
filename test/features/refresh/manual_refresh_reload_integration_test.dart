import 'package:flutter/foundation.dart';
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
import 'package:quota_analytics/features/refresh/data/services/page_load_waiter.dart';
import 'package:quota_analytics/features/refresh/data/services/webview_reload_service.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_page_state.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_policy.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_result.dart';
import 'package:quota_analytics/features/refresh/domain/entities/reload_before_refresh_policy.dart';
import 'package:quota_analytics/features/refresh/domain/entities/reload_before_refresh_result.dart';
import 'package:quota_analytics/features/refresh/domain/entities/reload_before_refresh_status.dart';
import 'package:quota_analytics/features/refresh/domain/repositories/manual_refresh_repository.dart';
import 'package:quota_analytics/features/refresh/domain/usecases/reload_page_before_refresh.dart';
import 'package:quota_analytics/features/refresh/domain/usecases/refresh_quota_from_webview.dart';
import 'package:quota_analytics/features/refresh/domain/usecases/save_manual_refresh_snapshot.dart';
import 'package:quota_analytics/features/refresh/presentation/controllers/manual_refresh_controller.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1, 12);

  test('reload disabled -> extraction called directly', () async {
    final harness = _Harness(now: now, reloadEnabled: false);

    await harness.controller.refreshFromCurrentPage(harness.pageState());

    expect(harness.reloadService.reloadCalls, 0);
    expect(harness.extractionRepository.extractCalls, 1);
    expect(harness.parserRepository.parseCalls, 1);
  });

  test('reload enabled -> reload called before extraction', () async {
    final events = <String>[];
    final harness = _Harness(now: now, events: events);

    await harness.controller.refreshFromCurrentPage(harness.pageState());

    expect(events, containsAllInOrder(['reload', 'extract', 'parse']));
    expect(
      harness.controller.lastResult.reloadBeforeRefreshResult?.status,
      ReloadBeforeRefreshStatus.completed,
    );
  });

  test('reload timeout -> extraction not called', () async {
    final harness = _Harness(
      now: now,
      autoFinishReload: false,
      reloadTimeout: const Duration(milliseconds: 5),
    );

    await harness.controller.refreshFromCurrentPage(harness.pageState());

    expect(harness.reloadService.reloadCalls, 1);
    expect(harness.extractionRepository.extractCalls, 0);
    expect(harness.parserRepository.parseCalls, 0);
    expect(
      harness.controller.lastResult.reloadBeforeRefreshResult?.status,
      ReloadBeforeRefreshStatus.timeout,
    );
  });

  test('reload loginRequired -> parser not called', () async {
    final harness = _Harness(
      now: now,
      urlAfterReload: 'https://chatgpt.com/auth/login?token=secret',
    );

    await harness.controller.refreshFromCurrentPage(harness.pageState());

    expect(harness.extractionRepository.extractCalls, 0);
    expect(harness.parserRepository.parseCalls, 0);
    expect(
      harness.controller.lastResult.reloadBeforeRefreshResult?.status,
      ReloadBeforeRefreshStatus.loginRequired,
    );
  });

  test(
    'reload success -> parser called and result contains reload summary',
    () async {
      final harness = _Harness(now: now);

      await harness.controller.refreshFromCurrentPage(harness.pageState());

      final reloadResult =
          harness.controller.lastResult.reloadBeforeRefreshResult;
      expect(harness.parserRepository.parseCalls, 1);
      expect(reloadResult?.status, ReloadBeforeRefreshStatus.completed);
      expect(
        reloadResult?.sanitizedUrl,
        'https://chatgpt.com/codex/cloud/settings/analytics',
      );
      expect(
        '${reloadResult?.warnings} ${reloadResult?.errors}',
        isNot(contains('5-hour window Used 10 of 50')),
      );
    },
  );
}

class _Harness {
  _Harness({
    required this.now,
    this.reloadEnabled = true,
    this.autoFinishReload = true,
    this.urlAfterReload,
    this.reloadTimeout = const Duration(milliseconds: 80),
    List<String>? events,
  }) : events = events ?? <String>[] {
    reloadService = _FakeWebViewReloadService(
      events: this.events,
      autoFinish: autoFinishReload,
      urlAfterReload: urlAfterReload,
    );
    extractionRepository = _FakeExtractionRepository(
      events: this.events,
      result: _extraction(now, '5-hour window Used 10 of 50'),
    );
    parserRepository = _FakeParserRepository(this.events, _parseResult(now));
    manualRepository = _FakeManualRefreshRepository();
    final saveUseCase = SaveManualRefreshSnapshot(
      quotaRepository: _FakeQuotaRepository(),
      manualRefreshRepository: manualRepository,
      clock: FixedClock(now),
    );
    controller = ManualRefreshController(
      refreshQuotaFromWebView: RefreshQuotaFromWebView(
        extractionRepository: extractionRepository,
        parserRepository: parserRepository,
        mapper: const ParseResultToQuotaSnapshotMapper(),
        manualRefreshRepository: manualRepository,
        saveManualRefreshSnapshot: saveUseCase,
        clock: FixedClock(now),
      ),
      saveManualRefreshSnapshot: saveUseCase,
      manualRefreshRepository: manualRepository,
      policyProvider: ManualRefreshPolicy.defaults,
      reloadPageBeforeRefresh: ReloadPageBeforeRefreshUseCase(
        reloadService: reloadService,
        pageLoadWaiter: const PageLoadWaiter(),
        clock: FixedClock(now),
      ),
      reloadBeforeManualRefreshPolicyProvider: () =>
          ReloadBeforeRefreshPolicy.manualDefault(
            enabled: reloadEnabled,
          ).copyWith(
            reloadTimeout: reloadTimeout,
            pageSettleDelay: const Duration(milliseconds: 1),
            reloadCooldown: const Duration(milliseconds: 20),
          ),
      currentPageStateProvider: pageState,
      clock: FixedClock(now),
    );
  }

  final DateTime now;
  final bool reloadEnabled;
  final bool autoFinishReload;
  final String? urlAfterReload;
  final Duration reloadTimeout;
  final List<String> events;
  late final _FakeWebViewReloadService reloadService;
  late final _FakeExtractionRepository extractionRepository;
  late final _FakeParserRepository parserRepository;
  late final _FakeManualRefreshRepository manualRepository;
  late final ManualRefreshController controller;

  ManualRefreshPageState pageState() {
    return ManualRefreshPageState(
      currentUrl: reloadService.currentUrl,
      pageTitle: 'Usage',
      isLoading: reloadService.isPageLoading,
      isReady: reloadService.hasWebView,
    );
  }
}

ExtractedPageText _extraction(DateTime extractedAt, String text) {
  return ExtractedPageText(
    id: 'manual-webview-1',
    sanitizedUrl: 'https://chatgpt.com/codex/cloud/settings/analytics',
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
    warnings: const [],
    errors: const [],
    parsedAt: parsedAt,
    parserVersion: 'fake-parser',
  );
}

class _FakeWebViewReloadService extends ChangeNotifier
    implements WebViewReloadService {
  _FakeWebViewReloadService({
    required this.events,
    this.autoFinish = true,
    this.urlAfterReload,
  });

  final List<String> events;
  final bool autoFinish;
  final String? urlAfterReload;

  @override
  bool hasWebView = true;

  @override
  String currentUrl = 'https://chatgpt.com/codex/cloud/settings/analytics';

  @override
  bool isPageLoading = false;

  @override
  DateTime? lastPageFinishedAt;

  @override
  DateTime? lastWebResourceErrorAt;

  @override
  String? lastWebResourceError;

  int reloadCalls = 0;
  DateTime? startedAt;
  ReloadBeforeRefreshResult? lastRecordedResult;

  @override
  Future<void> reload() async {
    events.add('reload');
    reloadCalls += 1;
    isPageLoading = true;
    notifyListeners();
    if (!autoFinish) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
    currentUrl = urlAfterReload ?? currentUrl;
    isPageLoading = false;
    lastPageFinishedAt = (startedAt ?? DateTime.now()).add(
      const Duration(milliseconds: 1),
    );
    notifyListeners();
  }

  @override
  void recordReloadStarted(DateTime startedAt) {
    this.startedAt = startedAt;
  }

  @override
  void recordReloadResult(
    ReloadBeforeRefreshResult result, {
    DateTime? cooldownUntil,
  }) {
    lastRecordedResult = result;
  }
}

class _FakeExtractionRepository implements PageTextExtractionRepository {
  _FakeExtractionRepository({required this.events, required this.result});

  final List<String> events;
  final ExtractedPageText result;
  int extractCalls = 0;

  @override
  void attachPageTextReader(CurrentPageTextReader reader) {}

  @override
  Future<void> clearExtractedPageText() async {}

  @override
  Future<ExtractedPageText> extractCurrentPageText() async {
    events.add('extract');
    extractCalls += 1;
    return result;
  }

  @override
  Future<ExtractedPageText?> getLastExtractedPageText() async => null;
}

class _FakeParserRepository implements QuotaParserRepository {
  _FakeParserRepository(this.events, this.result);

  final List<String> events;
  final QuotaParseResult result;
  int parseCalls = 0;

  @override
  QuotaParseResult parse(String text, {DateTime? now}) {
    events.add('parse');
    parseCalls += 1;
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
  Future<ManualRefreshResult?> getLastResult() async => last;

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
  Future<QuotaSnapshot> getLatestSnapshot() async => saved!;

  @override
  Future<QuotaPersistenceStatus> getPersistenceStatus() async {
    return QuotaPersistenceStatus.mockOnly();
  }

  @override
  Future<QuotaSnapshot> refreshSnapshot() async => saved!;

  @override
  Future<QuotaSnapshot> saveSnapshot(QuotaSnapshot snapshot) async {
    saved = snapshot;
    return snapshot;
  }
}
