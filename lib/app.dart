import 'dart:async';

import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/time/clock.dart';
import 'features/debug/presentation/pages/debug_page.dart';
import 'features/quota/data/datasources/mock_quota_datasource.dart';
import 'features/quota/data/repositories/mock_quota_repository.dart';
import 'features/quota/domain/repositories/quota_repository.dart';
import 'features/quota/presentation/controllers/quota_controller.dart';
import 'features/quota/presentation/pages/quota_home_page.dart';
import 'features/settings/data/mock_settings_repository.dart';
import 'features/settings/presentation/pages/settings_page.dart';

class QuotaAnalyticsApp extends StatelessWidget {
  const QuotaAnalyticsApp({
    super.key,
    this.quotaRepository,
    this.settingsRepository,
    this.clock,
  });

  final QuotaRepository? quotaRepository;
  final MockSettingsRepository? settingsRepository;
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
  final MockSettingsRepository? settingsRepository;
  final Clock? clock;

  @override
  State<QuotaShell> createState() => _QuotaShellState();
}

class _QuotaShellState extends State<QuotaShell> {
  late final QuotaController _quotaController;
  late final MockSettingsRepository _settingsRepository;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final effectiveClock = widget.clock ?? const SystemClock();
    final repository =
        widget.quotaRepository ??
        MockQuotaRepository(MockQuotaDataSource(clock: effectiveClock));

    _quotaController = QuotaController(repository: repository);
    _settingsRepository = widget.settingsRepository ?? MockSettingsRepository();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_quotaController.loadLatestSnapshot());
    });
  }

  @override
  void dispose() {
    _quotaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      QuotaHomePage(controller: _quotaController),
      SettingsPage(repository: _settingsRepository),
      DebugPage(controller: _quotaController),
    ];

    return AnimatedBuilder(
      animation: _quotaController,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_titleForIndex(_selectedIndex)),
            actions: [
              if (_selectedIndex == 0)
                IconButton(
                  tooltip: 'Refresh mock quota',
                  onPressed: _quotaController.isLoading
                      ? null
                      : () => unawaited(_quotaController.refresh()),
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

  String _titleForIndex(int index) {
    return switch (index) {
      0 => AppConstants.appName,
      1 => 'Settings',
      _ => 'Debug',
    };
  }
}
