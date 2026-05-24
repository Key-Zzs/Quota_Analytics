import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/auto_refresh/domain/entities/auto_refresh_policy.dart';
import 'package:quota_analytics/features/auto_refresh/domain/entities/auto_refresh_result.dart';
import 'package:quota_analytics/features/auto_refresh/domain/entities/auto_refresh_status.dart';
import 'package:quota_analytics/features/auto_refresh/domain/repositories/auto_refresh_repository.dart';
import 'package:quota_analytics/features/auto_refresh/domain/usecases/evaluate_auto_refresh_eligibility.dart';
import 'package:quota_analytics/features/auto_refresh/domain/usecases/run_foreground_auto_refresh.dart';
import 'package:quota_analytics/features/auto_refresh/presentation/controllers/foreground_auto_refresh_controller.dart';
import 'package:quota_analytics/features/auth/domain/entities/webview_clear_result.dart';
import 'package:quota_analytics/features/auth/domain/repositories/web_auth_repository.dart';
import 'package:quota_analytics/features/auth/presentation/controllers/webview_auth_controller.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extracted_page_text.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_safety_status.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_source.dart';
import 'package:quota_analytics/features/extraction/domain/repositories/page_text_extraction_repository.dart';
import 'package:quota_analytics/features/parser/data/mappers/parse_result_to_quota_snapshot_mapper.dart';
import 'package:quota_analytics/features/parser/data/parsers/regex_quota_parser.dart';
import 'package:quota_analytics/features/parser/data/repositories/quota_parser_repository_impl.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';
import 'package:quota_analytics/features/quota/domain/entities/parser_confidence.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_persistence_status.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_snapshot.dart';
import 'package:quota_analytics/features/quota/domain/repositories/quota_repository.dart';
import 'package:quota_analytics/features/refresh/data/services/page_load_waiter.dart';
import 'package:quota_analytics/features/refresh/data/services/webview_reload_service.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_page_state.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_policy.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_result.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_status.dart';
import 'package:quota_analytics/features/refresh/domain/entities/reload_before_refresh_policy.dart';
import 'package:quota_analytics/features/refresh/domain/entities/reload_before_refresh_result.dart';
import 'package:quota_analytics/features/refresh/domain/entities/reload_before_refresh_status.dart';
import 'package:quota_analytics/features/refresh/domain/repositories/manual_refresh_repository.dart';
import 'package:quota_analytics/features/refresh/domain/usecases/reload_page_before_refresh.dart';
import 'package:quota_analytics/features/refresh/domain/usecases/refresh_quota_from_webview.dart';
import 'package:quota_analytics/features/refresh/domain/usecases/save_manual_refresh_snapshot.dart';
import 'package:quota_analytics/features/refresh/presentation/controllers/manual_refresh_controller.dart';
import 'package:quota_analytics/features/settings/data/mock_settings_repository.dart';
import 'package:quota_analytics/features/settings/domain/entities/refresh_interval.dart';
import 'package:quota_analytics/features/settings/presentation/controllers/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resumed triggers eligibility check and refresh', () async {
    final harness = await _buildHarness(
      initialLifecycleState: AppLifecycleState.paused,
    );

    harness.controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);

    expect(harness.repository.calls, 1);
    expect(harness.controller.state.status, AutoRefreshStatus.success);
    harness.dispose();
  });

  test('paused cancels timer', () async {
    final harness = await _buildHarness();

    expect(harness.scheduler.isActive, isTrue);

    harness.controller.didChangeAppLifecycleState(AppLifecycleState.paused);

    expect(harness.scheduler.isActive, isFalse);
    expect(
      harness.controller.state.status,
      AutoRefreshStatus.skippedNotForeground,
    );
    harness.dispose();
  });

  test('dispose cancels timer', () async {
    final harness = await _buildHarness();

    expect(harness.scheduler.isActive, isTrue);

    harness.dispose();

    expect(harness.scheduler.isActive, isFalse);
  });

  test('no duplicate refresh while one is in progress', () async {
    final completer = Completer<AutoRefreshResult>();
    final harness = await _buildHarness(completer: completer);

    final first = harness.controller.checkNow();
    final second = harness.controller.checkNow();
    await Future<void>.delayed(Duration.zero);

    expect(harness.repository.calls, 1);

    completer.complete(_autoResult(ManualRefreshStatus.saved));
    await Future.wait([first, second]);

    expect(harness.controller.state.status, AutoRefreshStatus.success);
    harness.dispose();
  });

  test('failed refresh enters cooldown', () async {
    final harness = await _buildHarness(
      result: _autoResult(
        ManualRefreshStatus.parseFailed,
        errors: const ['Parse failed'],
      ),
    );

    await harness.controller.checkNow();

    expect(harness.repository.calls, 1);
    expect(harness.controller.state.status, AutoRefreshStatus.failed);
    expect(harness.controller.state.cooldownUntil, isNotNull);

    await harness.controller.checkNow();

    expect(harness.repository.calls, 1);
    expect(harness.controller.state.status, AutoRefreshStatus.cooldown);
    harness.dispose();
  });

  test('eligible auto refresh calls manual refresh once', () async {
    final harness = await _buildHarness();

    await harness.controller.checkNow();

    expect(harness.repository.calls, 1);
    harness.dispose();
  });

  test('successful manual refresh resets next foreground auto refresh time', () async {
    final harness = await _buildHarness(
      manualExtractionText: '''
5-hour window
Used 10 of 50
resets in 2 hours
Weekly quota
Used 200 of 1000
resets on Monday
''',
    );

    await harness.manualRefreshController.refreshFromCurrentPage(
      const ManualRefreshPageState(
        currentUrl: 'https://chatgpt.com/codex/cloud/settings/analytics',
        pageTitle: 'Analytics',
        isLoading: false,
        isReady: true,
      ),
    );

    expect(harness.controller.state.lastAttemptAt, DateTime(2026, 1, 1, 12));
    expect(harness.controller.state.lastSuccessAt, DateTime(2026, 1, 1, 12));
    expect(
      harness.controller.state.nextEligibleAt,
      DateTime(2026, 1, 1, 12, 5),
    );
    harness.dispose();
  });

  test(
    'high confidence saved result is forwarded to quota UI callback',
    () async {
      QuotaSnapshot? saved;
      final snapshot = QuotaSnapshotModel.mock(
        capturedAt: DateTime(2026, 1, 1, 12),
        variant: 1,
      );
      final harness = await _buildHarness(
        result: _autoResult(ManualRefreshStatus.saved, savedSnapshot: snapshot),
        onSnapshotSaved: (value) => saved = value,
      );

      await harness.controller.checkNow();

      expect(saved, snapshot);
      expect(harness.controller.state.status, AutoRefreshStatus.success);
      harness.dispose();
    },
  );

  test('failed result does not overwrite latest snapshot callback', () async {
    QuotaSnapshot? saved;
    final harness = await _buildHarness(
      result: _autoResult(
        ManualRefreshStatus.extractionFailed,
        errors: const ['Extraction failed'],
      ),
      onSnapshotSaved: (value) => saved = value,
    );

    await harness.controller.checkNow();

    expect(saved, isNull);
    expect(harness.controller.state.status, AutoRefreshStatus.failed);
    harness.dispose();
  });

  test('reload-before-auto enabled -> reload first', () async {
    final events = <String>[];
    final harness = await _buildHarness(
      reloadBeforeAutoEnabled: true,
      reloadService: _FakeReloadService(events: events),
      events: events,
    );

    await harness.controller.checkNow();

    expect(events, containsAllInOrder(['reload', 'refresh']));
    expect(harness.repository.calls, 1);
    expect(
      harness.repository.lastReloadBeforeRefreshResult?.status,
      ReloadBeforeRefreshStatus.completed,
    );
    harness.dispose();
  });

  test('app not resumed -> no reload', () async {
    final events = <String>[];
    final harness = await _buildHarness(
      initialLifecycleState: AppLifecycleState.paused,
      reloadBeforeAutoEnabled: true,
      reloadService: _FakeReloadService(events: events),
      events: events,
    );

    await harness.controller.checkNow();

    expect(events, isEmpty);
    expect(harness.repository.calls, 0);
    expect(
      harness.controller.state.status,
      AutoRefreshStatus.skippedNotForeground,
    );
    harness.dispose();
  });

  test('app paused during reload -> cancelled without extraction', () async {
    final events = <String>[];
    final harness = await _buildHarness(
      reloadBeforeAutoEnabled: true,
      reloadService: _FakeReloadService(events: events, autoFinish: false),
      reloadTimeout: const Duration(milliseconds: 80),
      events: events,
    );

    final future = harness.controller.checkNow();
    await Future<void>.delayed(Duration.zero);
    harness.controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    await future;

    expect(events, ['reload']);
    expect(harness.repository.calls, 0);
    expect(
      harness.controller.state.status,
      AutoRefreshStatus.skippedNotForeground,
    );
    harness.dispose();
  });

  test('reload timeout -> auto refresh records failure and cooldown', () async {
    final events = <String>[];
    final harness = await _buildHarness(
      reloadBeforeAutoEnabled: true,
      reloadService: _FakeReloadService(events: events, autoFinish: false),
      reloadTimeout: const Duration(milliseconds: 5),
      events: events,
    );

    await harness.controller.checkNow();

    expect(harness.repository.calls, 0);
    expect(harness.controller.state.status, AutoRefreshStatus.failed);
    expect(harness.controller.state.cooldownUntil, isNotNull);
    expect(harness.controller.state.lastError, contains('timed out'));
    harness.dispose();
  });

  test('no duplicate refresh while reload active', () async {
    final events = <String>[];
    final harness = await _buildHarness(
      reloadBeforeAutoEnabled: true,
      reloadService: _FakeReloadService(events: events, autoFinish: false),
      reloadTimeout: const Duration(milliseconds: 20),
      events: events,
    );

    final first = harness.controller.checkNow();
    final second = harness.controller.checkNow();
    await Future.wait([first, second]);

    expect(events.where((event) => event == 'reload').length, 1);
    expect(harness.repository.calls, 0);
    harness.dispose();
  });
}

Future<_Harness> _buildHarness({
  AppLifecycleState initialLifecycleState = AppLifecycleState.resumed,
  AutoRefreshResult? result,
  Completer<AutoRefreshResult>? completer,
  ValueChanged<QuotaSnapshot>? onSnapshotSaved,
  bool reloadBeforeAutoEnabled = false,
  _FakeReloadService? reloadService,
  Duration reloadTimeout = const Duration(milliseconds: 80),
  List<String>? events,
  String manualExtractionText = 'Used 1 of 10',
}) async {
  final clock = FixedClock(DateTime(2026, 1, 1, 12));
  final settingsController = SettingsController(
    repository: MockSettingsRepository(),
  );
  await settingsController.load();
  settingsController.setRefreshInterval(RefreshInterval.fiveMinutes);
  settingsController.setReloadBeforeForegroundAutoRefreshEnabled(
    reloadBeforeAutoEnabled,
  );

  final webAuthController = WebViewAuthController(
    repository: _FakeWebAuthRepository(),
    clock: clock,
  );
  await webAuthController.onPageFinished(
    'https://chatgpt.com/codex/cloud/settings/analytics',
  );

  final manualRefreshController = _manualRefreshController(
    clock,
    extractionText: manualExtractionText,
  );
  final policy = const AutoRefreshPolicy(
    checkInterval: Duration(seconds: 60),
    failureCooldown: Duration(minutes: 5),
  );
  final repository = _FakeAutoRefreshRepository(
    result: result ?? _autoResult(ManualRefreshStatus.awaitingUserConfirmation),
    completer: completer,
    events: events,
  );
  final scheduler = _ManualScheduler();
  final controller = ForegroundAutoRefreshController(
    settingsController: settingsController,
    webAuthController: webAuthController,
    manualRefreshController: manualRefreshController,
    reloadPageBeforeRefresh: reloadService == null
        ? null
        : ReloadPageBeforeRefreshUseCase(
            reloadService: reloadService,
            pageLoadWaiter: const PageLoadWaiter(),
            clock: clock,
          ),
    reloadBeforeForegroundAutoRefreshPolicyProvider: () =>
        ReloadBeforeRefreshPolicy.foregroundAutoDefault(
          enabled: reloadBeforeAutoEnabled,
        ).copyWith(
          reloadTimeout: reloadTimeout,
          pageSettleDelay: const Duration(milliseconds: 1),
          reloadCooldown: const Duration(milliseconds: 20),
        ),
    evaluateEligibility: EvaluateAutoRefreshEligibility(policy: policy),
    runForegroundAutoRefresh: RunForegroundAutoRefresh(repository),
    policy: policy,
    onSnapshotSaved: onSnapshotSaved,
    clock: clock,
    scheduler: scheduler,
    initialLifecycleState: initialLifecycleState,
    registerLifecycleObserver: false,
  );
  return _Harness(
    controller: controller,
    repository: repository,
    scheduler: scheduler,
    manualRefreshController: manualRefreshController,
    settingsController: settingsController,
    webAuthController: webAuthController,
  );
}

ManualRefreshController _manualRefreshController(
  Clock clock, {
  required String extractionText,
}) {
  final manualRefreshRepository = _FakeManualRefreshRepository();
  final saveUseCase = SaveManualRefreshSnapshot(
    quotaRepository: _FakeQuotaRepository(),
    manualRefreshRepository: manualRefreshRepository,
    clock: clock,
  );
  return ManualRefreshController(
    refreshQuotaFromWebView: RefreshQuotaFromWebView(
      extractionRepository: _FakeExtractionRepository(text: extractionText),
      parserRepository: QuotaParserRepositoryImpl(parser: RegexQuotaParser()),
      mapper: const ParseResultToQuotaSnapshotMapper(),
      manualRefreshRepository: manualRefreshRepository,
      saveManualRefreshSnapshot: saveUseCase,
      clock: clock,
    ),
    saveManualRefreshSnapshot: saveUseCase,
    manualRefreshRepository: manualRefreshRepository,
    policyProvider: ManualRefreshPolicy.defaults,
    clock: clock,
  );
}

AutoRefreshResult _autoResult(
  ManualRefreshStatus status, {
  List<String> errors = const [],
  QuotaSnapshot? savedSnapshot,
}) {
  final snapshot =
      savedSnapshot ??
      QuotaSnapshotModel.mock(capturedAt: DateTime(2026, 1, 1, 12), variant: 1);
  return AutoRefreshResult(
    manualRefreshResult: ManualRefreshResult(
      status: status,
      safetyStatus: ExtractionSafetyStatus.allowed,
      parserConfidence: ParserConfidence.high,
      extractedPageText: null,
      parseResult: null,
      snapshotCandidate: errors.isEmpty ? snapshot : null,
      redactionSummary: null,
      warnings: const [],
      errors: errors,
      startedAt: DateTime(2026, 1, 1, 12),
      finishedAt: DateTime(2026, 1, 1, 12),
      savedSnapshotId: status == ManualRefreshStatus.saved ? snapshot.id : null,
    ),
    savedSnapshot: status == ManualRefreshStatus.saved ? snapshot : null,
  );
}

class _Harness {
  const _Harness({
    required this.controller,
    required this.repository,
    required this.scheduler,
    required this.manualRefreshController,
    required this.settingsController,
    required this.webAuthController,
  });

  final ForegroundAutoRefreshController controller;
  final _FakeAutoRefreshRepository repository;
  final _ManualScheduler scheduler;
  final ManualRefreshController manualRefreshController;
  final SettingsController settingsController;
  final WebViewAuthController webAuthController;

  void dispose() {
    controller.dispose();
    manualRefreshController.dispose();
    settingsController.dispose();
    webAuthController.dispose();
  }
}

class _ManualScheduler implements AutoRefreshScheduler {
  VoidCallback? tick;
  bool _isActive = false;

  @override
  bool get isActive => _isActive;

  @override
  void start(Duration interval, VoidCallback onTick) {
    _isActive = true;
    tick = onTick;
  }

  @override
  void stop() {
    _isActive = false;
    tick = null;
  }
}

class _FakeAutoRefreshRepository implements AutoRefreshRepository {
  _FakeAutoRefreshRepository({
    required this.result,
    this.completer,
    this.events,
  });

  final AutoRefreshResult result;
  final Completer<AutoRefreshResult>? completer;
  final List<String>? events;
  int calls = 0;
  ReloadBeforeRefreshResult? lastReloadBeforeRefreshResult;

  @override
  bool get isRefreshInProgress => completer != null && !completer!.isCompleted;

  @override
  Future<AutoRefreshResult> refreshCurrentPage(
    ManualRefreshPageState pageState, {
    bool reloadBeforeRefresh = false,
    ReloadCancellationSignal? cancellationSignal,
    ReloadBeforeRefreshResult? reloadBeforeRefreshResult,
  }) {
    events?.add('refresh');
    calls += 1;
    lastReloadBeforeRefreshResult = reloadBeforeRefreshResult;
    return completer?.future ?? Future.value(result);
  }
}

class _FakeReloadService extends ChangeNotifier
    implements WebViewReloadService {
  _FakeReloadService({required this.events, this.autoFinish = true});

  final List<String> events;
  final bool autoFinish;

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

  DateTime? startedAt;
  ReloadBeforeRefreshResult? lastResult;

  @override
  Future<void> reload() async {
    events.add('reload');
    isPageLoading = true;
    notifyListeners();
    if (!autoFinish) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
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
    lastResult = result;
  }
}

class _FakeWebAuthRepository implements WebAuthRepository {
  @override
  Future<bool> canGoBack() async => false;

  @override
  Future<bool> canGoForward() async => false;

  @override
  Future<WebViewClearResult> clearWebViewData() async {
    return const WebViewClearResult(
      cacheCleared: true,
      localStorageCleared: true,
      cookiesCleared: true,
    );
  }

  @override
  Future<String?> currentUrl() async {
    return 'https://chatgpt.com/codex/cloud/settings/analytics';
  }

  @override
  Future<void> goBack() async {}

  @override
  Future<void> goForward() async {}

  @override
  Future<void> load(Uri uri) async {}

  @override
  Future<String?> pageTitle() async => 'Analytics';

  @override
  Future<void> reload() async {}
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
  Future<QuotaSnapshot> getLatestSnapshot() async {
    return saved ??
        QuotaSnapshotModel.mock(
          capturedAt: DateTime(2026, 1, 1, 12),
          variant: 1,
        );
  }

  @override
  Future<QuotaPersistenceStatus> getPersistenceStatus() async {
    return QuotaPersistenceStatus.mockOnly();
  }

  @override
  Future<QuotaSnapshot> refreshSnapshot() async {
    return getLatestSnapshot();
  }

  @override
  Future<QuotaSnapshot> saveSnapshot(QuotaSnapshot snapshot) async {
    saved = snapshot;
    return snapshot;
  }
}

class _FakeExtractionRepository implements PageTextExtractionRepository {
  const _FakeExtractionRepository({required this.text});

  final String text;

  @override
  void attachPageTextReader(CurrentPageTextReader reader) {}

  @override
  Future<void> clearExtractedPageText() async {}

  @override
  Future<ExtractedPageText> extractCurrentPageText() async {
    return ExtractedPageText(
      id: 'manual-webview-1',
      sanitizedUrl: 'https://chatgpt.com/codex/cloud/settings/analytics',
      pageTitle: 'Analytics',
      redactedTextPreview: text,
      originalLength: text.length,
      redactedLength: text.length,
      redactedEmailCount: 0,
      redactedTokenCount: 0,
      redactedApiKeyCount: 0,
      redactedSecretCount: 0,
      truncated: false,
      extractedAt: DateTime(2026, 1, 1, 12),
      source: ExtractionSource.webViewManual,
      safetyStatus: ExtractionSafetyStatus.allowed,
    );
  }

  @override
  Future<ExtractedPageText?> getLastExtractedPageText() async => null;
}
