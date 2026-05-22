import 'dart:async';

import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/storage/json_storage.dart';
import 'core/storage/shared_preferences_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/time/clock.dart';
import 'features/auth/presentation/controllers/webview_auth_controller.dart';
import 'features/auth/presentation/pages/webview_login_page.dart';
import 'features/debug/presentation/pages/debug_page.dart';
import 'features/quota/data/datasources/local_quota_datasource.dart';
import 'features/quota/data/datasources/mock_quota_datasource.dart';
import 'features/quota/data/repositories/persistent_quota_repository.dart';
import 'features/quota/domain/repositories/quota_repository.dart';
import 'features/quota/presentation/controllers/quota_controller.dart';
import 'features/quota/presentation/pages/quota_home_page.dart';
import 'features/settings/data/datasources/local_settings_datasource.dart';
import 'features/settings/data/repositories/local_settings_repository.dart';
import 'features/settings/domain/repositories/settings_repository.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';
import 'features/settings/presentation/pages/settings_page.dart';

class QuotaAnalyticsApp extends StatelessWidget {
  const QuotaAnalyticsApp({
    super.key,
    this.quotaRepository,
    this.settingsRepository,
    this.clock,
  });

  final QuotaRepository? quotaRepository;
  final SettingsRepository? settingsRepository;
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
    this.clock,
  });

  final QuotaRepository? quotaRepository;
  final SettingsRepository? settingsRepository;
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
      QuotaHomePage(controller: quotaController),
      SettingsPage(
        controller: settingsController,
        onClearLocalData: _clearAllLocalData,
      ),
      _buildWebLoginPage(controllers),
      DebugPage(
        controller: quotaController,
        settingsController: settingsController,
        webAuthController: controllers.webAuthController,
        onClearLocalData: _clearAllLocalData,
      ),
    ];

    return AnimatedBuilder(
      animation: quotaController,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_titleForIndex(_selectedIndex)),
            actions: [
              if (_selectedIndex == 0)
                IconButton(
                  tooltip: 'Refresh mock quota',
                  onPressed: quotaController.isLoading
                      ? null
                      : () => unawaited(quotaController.refresh()),
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
      );
    }
    return const SizedBox.shrink();
  }

  Future<_AppControllers> _createControllers() async {
    final effectiveClock = widget.clock ?? const SystemClock();
    final storage = await _createStorageIfNeeded();
    final quotaRepository =
        widget.quotaRepository ??
        PersistentQuotaRepository(
          mockDataSource: MockQuotaDataSource(clock: effectiveClock),
          localDataSource: LocalQuotaDataSource(
            storage: storage!,
            clock: effectiveClock,
          ),
        );
    final settingsRepository =
        widget.settingsRepository ??
        LocalSettingsRepository(
          dataSource: LocalSettingsDataSource(
            storage: storage!,
            clock: effectiveClock,
          ),
          clock: effectiveClock,
        );

    final controllers = _AppControllers(
      quotaController: QuotaController(repository: quotaRepository),
      settingsController: SettingsController(repository: settingsRepository),
      webAuthController: WebViewAuthController(clock: effectiveClock),
    );
    _controllers = controllers;

    await Future.wait([
      controllers.quotaController.loadLatestSnapshot(),
      controllers.settingsController.load(),
    ]);

    return controllers;
  }

  Future<JsonStorage?> _createStorageIfNeeded() async {
    if (widget.quotaRepository != null && widget.settingsRepository != null) {
      return null;
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
    required this.quotaController,
    required this.settingsController,
    required this.webAuthController,
  });

  final QuotaController quotaController;
  final SettingsController settingsController;
  final WebViewAuthController webAuthController;

  void dispose() {
    quotaController.dispose();
    settingsController.dispose();
    webAuthController.dispose();
  }
}
