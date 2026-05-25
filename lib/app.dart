import 'dart:async';

import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/storage/json_storage.dart';
import 'core/storage/memory_json_storage.dart';
import 'core/storage/shared_preferences_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/time/clock.dart';
import 'features/auto_refresh/data/repositories/foreground_auto_refresh_repository.dart';
import 'features/auto_refresh/domain/entities/auto_refresh_policy.dart';
import 'features/auto_refresh/domain/usecases/evaluate_auto_refresh_eligibility.dart';
import 'features/auto_refresh/domain/usecases/run_foreground_auto_refresh.dart';
import 'features/auto_refresh/presentation/controllers/foreground_auto_refresh_controller.dart';
import 'features/background_refresh/data/datasources/local_background_refresh_datasource.dart';
import 'features/background_refresh/data/datasources/workmanager_background_task_datasource.dart';
import 'features/background_refresh/data/repositories/background_refresh_repository_impl.dart';
import 'features/background_refresh/domain/usecases/evaluate_background_refresh_eligibility.dart';
import 'features/background_refresh/domain/usecases/run_background_refresh_check.dart';
import 'features/background_refresh/presentation/controllers/background_refresh_settings_controller.dart';
import 'features/auth/presentation/controllers/webview_auth_controller.dart';
import 'features/auth/presentation/pages/webview_login_page.dart';
import 'features/debug/presentation/pages/debug_page.dart';
import 'features/extraction/data/datasources/local_extracted_text_datasource.dart';
import 'features/extraction/data/repositories/page_text_extraction_repository_impl.dart';
import 'features/extraction/domain/repositories/page_text_extraction_repository.dart';
import 'features/extraction/presentation/controllers/page_text_extraction_controller.dart';
import 'features/parser/data/mappers/parse_result_to_quota_snapshot_mapper.dart';
import 'features/parser/data/parsers/regex_quota_parser.dart';
import 'features/parser/data/repositories/quota_parser_repository_impl.dart';
import 'features/parser/domain/repositories/quota_parser_repository.dart';
import 'features/parser/domain/usecases/save_parsed_quota_snapshot.dart';
import 'features/parser/presentation/controllers/quota_parser_controller.dart';
import 'features/notifications/data/datasources/local_notification_datasource.dart';
import 'features/notifications/data/datasources/notification_metadata_datasource.dart';
import 'features/notifications/data/repositories/local_notification_repository.dart';
import 'features/notifications/domain/usecases/evaluate_notification_rules.dart';
import 'features/notifications/domain/usecases/send_quota_notification.dart';
import 'features/quota/data/datasources/local_quota_datasource.dart';
import 'features/quota/data/datasources/mock_quota_datasource.dart';
import 'features/quota/data/repositories/persistent_quota_repository.dart';
import 'features/quota/domain/repositories/quota_repository.dart';
import 'features/quota/presentation/controllers/quota_controller.dart';
import 'features/quota/presentation/pages/quota_home_page.dart';
import 'features/refresh/data/datasources/local_manual_refresh_datasource.dart';
import 'features/refresh/data/repositories/manual_refresh_repository_impl.dart';
import 'features/refresh/data/services/page_load_waiter.dart';
import 'features/refresh/data/services/webview_reload_service.dart';
import 'features/refresh/domain/entities/manual_refresh_page_state.dart';
import 'features/refresh/domain/usecases/reload_page_before_refresh.dart';
import 'features/refresh/domain/usecases/refresh_quota_from_webview.dart';
import 'features/refresh/domain/usecases/save_manual_refresh_snapshot.dart';
import 'features/refresh/presentation/controllers/manual_refresh_controller.dart';
import 'features/settings/data/datasources/local_settings_datasource.dart';
import 'features/settings/data/repositories/local_settings_repository.dart';
import 'features/settings/domain/repositories/settings_repository.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/widget_export/data/datasources/local_widget_summary_datasource.dart';
import 'features/widget_export/data/mappers/quota_snapshot_to_widget_summary_mapper.dart';
import 'features/widget_export/data/repositories/widget_exporting_quota_repository.dart';
import 'features/widget_export/data/repositories/widget_summary_repository_impl.dart';
import 'features/widget_export/domain/usecases/clear_widget_summary.dart';
import 'features/widget_export/domain/usecases/export_widget_summary.dart';
import 'features/widget_export/domain/usecases/get_widget_summary.dart';
import 'features/widget_export/presentation/controllers/widget_export_controller.dart';

class QuotaAnalyticsApp extends StatelessWidget {
  const QuotaAnalyticsApp({
    super.key,
    this.quotaRepository,
    this.settingsRepository,
    this.pageTextExtractionRepository,
    this.quotaParserRepository,
    this.clock,
  });

  final QuotaRepository? quotaRepository;
  final SettingsRepository? settingsRepository;
  final PageTextExtractionRepository? pageTextExtractionRepository;
  final QuotaParserRepository? quotaParserRepository;
  final Clock? clock;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: QuotaShell(
        quotaRepository: quotaRepository,
        settingsRepository: settingsRepository,
        pageTextExtractionRepository: pageTextExtractionRepository,
        quotaParserRepository: quotaParserRepository,
        clock: clock,
      ),
    );
  }
}

class QuotaShell extends StatefulWidget {
  const QuotaShell({
    super.key,
    this.quotaRepository,
    this.settingsRepository,
    this.pageTextExtractionRepository,
    this.quotaParserRepository,
    this.clock,
  });

  final QuotaRepository? quotaRepository;
  final SettingsRepository? settingsRepository;
  final PageTextExtractionRepository? pageTextExtractionRepository;
  final QuotaParserRepository? quotaParserRepository;
  final Clock? clock;

  @override
  State<QuotaShell> createState() => _QuotaShellState();
}

class _QuotaShellState extends State<QuotaShell> {
  late final Future<_AppControllers> _controllersFuture;
  _AppControllers? _controllers;
  Widget? _webLoginPage;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controllersFuture = _createControllers();
  }

  @override
  void dispose() {
    _controllers?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppControllers>(
      future: _controllersFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppConstants.appName)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to initialize local persistence: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final controllers = snapshot.data;
        if (controllers == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppConstants.appName)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return _buildShell(context, controllers);
      },
    );
  }

  Widget _buildShell(BuildContext context, _AppControllers controllers) {
    final quotaController = controllers.quotaController;
    final settingsController = controllers.settingsController;
    final pages = <Widget>[
      QuotaHomePage(
        controller: quotaController,
        onGoToWebRefresh: () {
          setState(() {
            _selectedIndex = 2;
          });
        },
      ),
      SettingsPage(
        controller: settingsController,
        autoRefreshController: controllers.autoRefreshController,
        backgroundRefreshController: controllers.backgroundRefreshController,
        onClearLocalData: _clearAllLocalData,
      ),
      _buildWebLoginPage(controllers),
      DebugPage(
        controller: quotaController,
        settingsController: settingsController,
        webAuthController: controllers.webAuthController,
        pageTextExtractionController: controllers.pageTextExtractionController,
        quotaParserController: controllers.quotaParserController,
        manualRefreshController: controllers.manualRefreshController,
        autoRefreshController: controllers.autoRefreshController,
        backgroundRefreshController: controllers.backgroundRefreshController,
        widgetExportController: controllers.widgetExportController,
        onClearLocalData: _clearAllLocalData,
      ),
    ];

    return AnimatedBuilder(
      animation: Listenable.merge([
        quotaController,
        controllers.manualRefreshController,
        controllers.webAuthController,
      ]),
      builder: (context, _) {
        final manualRefreshController = controllers.manualRefreshController;
        final isQuotaRefreshBusy =
            quotaController.isLoading || manualRefreshController.isBusy;
        return Scaffold(
          appBar: AppBar(
            title: Text(_titleForIndex(_selectedIndex)),
            actions: [
              if (_selectedIndex == 0)
                IconButton(
                  tooltip: 'Refresh usage page',
                  onPressed: isQuotaRefreshBusy
                      ? null
                      : () => unawaited(_runQuotaPageUsageRefresh(controllers)),
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          body: IndexedStack(index: _selectedIndex, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.speed_outlined),
                selectedIcon: Icon(Icons.speed),
                label: 'Quota',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune),
                label: 'Settings',
              ),
              NavigationDestination(
                icon: Icon(Icons.lock_outline),
                selectedIcon: Icon(Icons.lock),
                label: 'Web Login',
              ),
              NavigationDestination(
                icon: Icon(Icons.bug_report_outlined),
                selectedIcon: Icon(Icons.bug_report),
                label: 'Debug',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebLoginPage(_AppControllers controllers) {
    if (_selectedIndex == 2 || _webLoginPage != null) {
      return _webLoginPage ??= WebViewLoginPage(
        controller: controllers.webAuthController,
        pageTextExtractionController: controllers.pageTextExtractionController,
        quotaParserController: controllers.quotaParserController,
        manualRefreshController: controllers.manualRefreshController,
        settingsController: controllers.settingsController,
        onParsedSnapshotSaved: controllers.quotaController.applySavedSnapshot,
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _runQuotaPageUsageRefresh(_AppControllers controllers) async {
    final quotaController = controllers.quotaController;
    final manualRefreshController = controllers.manualRefreshController;
    final webAuthController = controllers.webAuthController;
    if (quotaController.isLoading || manualRefreshController.isBusy) {
      return;
    }

    final stopwatch = Stopwatch()..start();
    quotaController.markExternalRefreshStarted(
      'Opening usage page for manual refresh',
    );

    try {
      final ready = await _ensureWebRefreshPageVisible(webAuthController);
      if (!ready) {
        throw StateError('WebView controller is not ready.');
      }

      final usageLoadResult = await _openUsagePageAndWait(controllers);
      if (usageLoadResult.status != PageLoadWaitStatus.completed) {
        throw StateError(_usagePageLoadError(usageLoadResult));
      }

      final saved = await manualRefreshController.refreshFromCurrentPage(
        ManualRefreshPageState(
          currentUrl: webAuthController.currentUrl,
          pageTitle: webAuthController.pageTitle,
          isLoading: webAuthController.isLoading,
          isReady: webAuthController.isReady,
        ),
        reloadBeforeRefresh: false,
        policyOverride: manualRefreshController.policy.copyWith(
          autoSaveHighConfidence: true,
        ),
      );
      stopwatch.stop();

      if (saved == null) {
        await quotaController.completeExternalRefreshWithoutSnapshot(
          'Manual refresh completed without a high-confidence saved snapshot',
          refreshDuration: stopwatch.elapsed,
        );
        return;
      }

      await quotaController.applySavedSnapshot(
        saved,
        resultMessage: 'Usage page manual refresh saved locally',
        refreshDuration: stopwatch.elapsed,
      );
      if (mounted) {
        setState(() {
          _selectedIndex = 0;
        });
      }
    } on Object catch (error) {
      stopwatch.stop();
      await quotaController.failExternalRefresh(
        'Usage page manual refresh failed',
        cause: error,
        refreshDuration: stopwatch.elapsed,
      );
    }
  }

  Future<bool> _ensureWebRefreshPageVisible(
    WebViewAuthController webAuthController,
  ) async {
    if (!mounted) {
      return false;
    }
    if (_selectedIndex != 2) {
      setState(() {
        _selectedIndex = 2;
      });
    }

    for (var attempt = 0; attempt < 3; attempt += 1) {
      await WidgetsBinding.instance.endOfFrame;
      if (webAuthController.isReady) {
        return true;
      }
    }
    return webAuthController.isReady;
  }

  Future<PageLoadWaitResult> _openUsagePageAndWait(
    _AppControllers controllers,
  ) async {
    final webAuthController = controllers.webAuthController;
    final loadStartedAt = controllers.clock.now();
    await webAuthController.openUsagePage();
    final reloadPolicy =
        controllers.settingsController.manualReloadBeforeRefreshPolicy;
    return const PageLoadWaiter().waitForPageFinished(
      pageState: WebViewAuthReloadService(controller: webAuthController),
      reloadStartedAt: loadStartedAt,
      timeout: reloadPolicy.reloadTimeout,
      settleDelay: reloadPolicy.pageSettleDelay,
    );
  }

  String _usagePageLoadError(PageLoadWaitResult result) {
    return switch (result.status) {
      PageLoadWaitStatus.completed => 'Usage page loaded.',
      PageLoadWaitStatus.timeout =>
        'Usage page did not finish loading before the refresh timeout.',
      PageLoadWaitStatus.cancelled => 'Usage page load was cancelled.',
      PageLoadWaitStatus.failed =>
        result.errorMessage ?? 'Usage page failed to load.',
    };
  }

  Future<_AppControllers> _createControllers() async {
    final effectiveClock = widget.clock ?? const SystemClock();
    final storage = await _createStorageIfNeeded();
    final widgetSummaryRepository = WidgetSummaryRepositoryImpl(
      dataSource: LocalWidgetSummaryDataSource(storage: storage),
      mapper: const QuotaSnapshotToWidgetSummaryMapper(),
      clock: effectiveClock,
    );
    final baseQuotaRepository =
        widget.quotaRepository ??
        PersistentQuotaRepository(
          mockDataSource: MockQuotaDataSource(clock: effectiveClock),
          localDataSource: LocalQuotaDataSource(
            storage: storage,
            clock: effectiveClock,
          ),
        );
    final quotaRepository = WidgetExportingQuotaRepository(
      delegate: baseQuotaRepository,
      widgetRepository: widgetSummaryRepository,
    );
    final settingsRepository =
        widget.settingsRepository ??
        LocalSettingsRepository(
          dataSource: LocalSettingsDataSource(
            storage: storage,
            clock: effectiveClock,
          ),
          clock: effectiveClock,
        );
    final pageTextExtractionRepository =
        widget.pageTextExtractionRepository ??
        PageTextExtractionRepositoryImpl(
          localDataSource: LocalExtractedTextDataSource(storage: storage),
          clock: effectiveClock,
        );
    final quotaParserRepository =
        widget.quotaParserRepository ??
        QuotaParserRepositoryImpl(parser: RegexQuotaParser());
    final manualRefreshRepository = ManualRefreshRepositoryImpl(
      localDataSource: LocalManualRefreshDataSource(
        storage: storage,
        clock: effectiveClock,
      ),
    );
    final backgroundRefreshRepository = BackgroundRefreshRepositoryImpl(
      localDataSource: LocalBackgroundRefreshDataSource(
        storage: storage,
        clock: effectiveClock,
      ),
      workmanagerDataSource: WorkmanagerBackgroundTaskDataSource(),
      clock: effectiveClock,
    );
    final notificationRepository = LocalNotificationRepository(
      notificationDataSource: LocalNotificationDataSource(),
      metadataDataSource: NotificationMetadataDataSource(storage: storage),
      clock: effectiveClock,
    );
    final settingsController = SettingsController(
      repository: settingsRepository,
    );
    final webAuthController = WebViewAuthController(clock: effectiveClock);
    final reloadPageBeforeRefresh = ReloadPageBeforeRefreshUseCase(
      reloadService: WebViewAuthReloadService(controller: webAuthController),
      pageLoadWaiter: const PageLoadWaiter(),
      clock: effectiveClock,
    );
    final saveManualRefreshSnapshot = SaveManualRefreshSnapshot(
      quotaRepository: quotaRepository,
      manualRefreshRepository: manualRefreshRepository,
      clock: effectiveClock,
    );

    final manualRefreshController = ManualRefreshController(
      refreshQuotaFromWebView: RefreshQuotaFromWebView(
        extractionRepository: pageTextExtractionRepository,
        parserRepository: quotaParserRepository,
        mapper: const ParseResultToQuotaSnapshotMapper(),
        manualRefreshRepository: manualRefreshRepository,
        saveManualRefreshSnapshot: saveManualRefreshSnapshot,
        clock: effectiveClock,
      ),
      saveManualRefreshSnapshot: saveManualRefreshSnapshot,
      manualRefreshRepository: manualRefreshRepository,
      policyProvider: () => settingsController.manualRefreshPolicy,
      reloadPageBeforeRefresh: reloadPageBeforeRefresh,
      reloadBeforeManualRefreshPolicyProvider: () =>
          settingsController.manualReloadBeforeRefreshPolicy,
      currentPageStateProvider: () => ManualRefreshPageState(
        currentUrl: webAuthController.currentUrl,
        pageTitle: webAuthController.pageTitle,
        isLoading: webAuthController.isLoading,
        isReady: webAuthController.isReady,
      ),
      clock: effectiveClock,
    );
    final autoRefreshPolicy = AutoRefreshPolicy();
    final autoRefreshRepository = ForegroundAutoRefreshRepository(
      manualRefreshController: manualRefreshController,
    );
    final quotaController = QuotaController(repository: quotaRepository);
    final autoRefreshController = ForegroundAutoRefreshController(
      settingsController: settingsController,
      webAuthController: webAuthController,
      manualRefreshController: manualRefreshController,
      reloadPageBeforeRefresh: reloadPageBeforeRefresh,
      evaluateEligibility: EvaluateAutoRefreshEligibility(
        policy: autoRefreshPolicy,
      ),
      runForegroundAutoRefresh: RunForegroundAutoRefresh(autoRefreshRepository),
      policy: autoRefreshPolicy,
      onSnapshotSaved: quotaController.applySavedSnapshot,
      clock: effectiveClock,
    );
    final runBackgroundRefreshCheck = RunBackgroundRefreshCheck(
      backgroundRepository: backgroundRefreshRepository,
      notificationRepository: notificationRepository,
      evaluateEligibility: const EvaluateBackgroundRefreshEligibility(),
      evaluateNotificationRules: const EvaluateNotificationRules(),
      sendQuotaNotification: SendQuotaNotification(notificationRepository),
    );
    final backgroundRefreshController = BackgroundRefreshSettingsController(
      backgroundRepository: backgroundRefreshRepository,
      notificationRepository: notificationRepository,
      runBackgroundRefreshCheck: runBackgroundRefreshCheck,
      clock: effectiveClock,
    );
    final widgetExportController = WidgetExportController(
      exportWidgetSummary: ExportWidgetSummary(widgetSummaryRepository),
      getWidgetSummary: GetWidgetSummary(widgetSummaryRepository),
      clearWidgetSummary: ClearWidgetSummary(widgetSummaryRepository),
    );

    final controllers = _AppControllers(
      clock: effectiveClock,
      quotaController: quotaController,
      settingsController: settingsController,
      webAuthController: webAuthController,
      pageTextExtractionController: PageTextExtractionController(
        repository: pageTextExtractionRepository,
      ),
      quotaParserController: QuotaParserController(
        repository: quotaParserRepository,
        mapper: const ParseResultToQuotaSnapshotMapper(),
        saveParsedQuotaSnapshot: SaveParsedQuotaSnapshot(quotaRepository),
      ),
      manualRefreshController: manualRefreshController,
      autoRefreshController: autoRefreshController,
      backgroundRefreshController: backgroundRefreshController,
      widgetExportController: widgetExportController,
    );
    _controllers = controllers;

    await controllers.quotaController.loadLatestSnapshot();
    await Future.wait([
      controllers.settingsController.load(),
      controllers.pageTextExtractionController.loadLastExtractedPageText(),
      controllers.manualRefreshController.loadLastResult(),
      controllers.backgroundRefreshController.load(),
    ]);
    await controllers.widgetExportController.load();

    return controllers;
  }

  Future<JsonStorage> _createStorageIfNeeded() async {
    if (widget.quotaRepository != null && widget.settingsRepository != null) {
      return MemoryJsonStorage();
    }
    return SharedPreferencesStorage.create();
  }

  Future<void> _clearAllLocalData() async {
    final controllers = _controllers;
    if (controllers == null) {
      return;
    }
    await controllers.quotaController.clearLocalData();
    await controllers.settingsController.clear();
    await controllers.pageTextExtractionController.clearExtractedPageText();
    controllers.quotaParserController.clearParseResult();
    await controllers.manualRefreshController.clearLastResult();
    await controllers.backgroundRefreshController.clear();
    await controllers.widgetExportController.clearSummary();
  }

  String _titleForIndex(int index) {
    return switch (index) {
      0 => AppConstants.appName,
      1 => 'Settings',
      2 => 'Web Login',
      _ => 'Debug',
    };
  }
}

class _AppControllers {
  const _AppControllers({
    required this.clock,
    required this.quotaController,
    required this.settingsController,
    required this.webAuthController,
    required this.pageTextExtractionController,
    required this.quotaParserController,
    required this.manualRefreshController,
    required this.autoRefreshController,
    required this.backgroundRefreshController,
    required this.widgetExportController,
  });

  final Clock clock;
  final QuotaController quotaController;
  final SettingsController settingsController;
  final WebViewAuthController webAuthController;
  final PageTextExtractionController pageTextExtractionController;
  final QuotaParserController quotaParserController;
  final ManualRefreshController manualRefreshController;
  final ForegroundAutoRefreshController autoRefreshController;
  final BackgroundRefreshSettingsController backgroundRefreshController;
  final WidgetExportController widgetExportController;

  void dispose() {
    autoRefreshController.dispose();
    backgroundRefreshController.dispose();
    widgetExportController.dispose();
    quotaController.dispose();
    settingsController.dispose();
    webAuthController.dispose();
    pageTextExtractionController.dispose();
    quotaParserController.dispose();
    manualRefreshController.dispose();
  }
}
