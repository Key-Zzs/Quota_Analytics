import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/security/sensitive_data_policy.dart';
import '../../../../core/time/clock.dart';
import '../../../auth/presentation/controllers/webview_auth_controller.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../../refresh/data/services/page_load_waiter.dart';
import '../../../refresh/domain/entities/manual_refresh_page_state.dart';
import '../../../refresh/domain/entities/manual_refresh_result.dart';
import '../../../refresh/domain/entities/manual_refresh_status.dart';
import '../../../refresh/domain/entities/reload_before_refresh_result.dart';
import '../../../refresh/domain/entities/reload_before_refresh_policy.dart';
import '../../../refresh/domain/usecases/reload_page_before_refresh.dart';
import '../../../refresh/presentation/controllers/manual_refresh_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/entities/auto_refresh_eligibility.dart';
import '../../domain/entities/auto_refresh_policy.dart';
import '../../domain/entities/auto_refresh_state.dart';
import '../../domain/entities/auto_refresh_status.dart';
import '../../domain/usecases/evaluate_auto_refresh_eligibility.dart';
import '../../domain/usecases/run_foreground_auto_refresh.dart';

abstract class AutoRefreshScheduler {
  bool get isActive;

  void start(Duration interval, VoidCallback onTick);

  void stop();
}

class TimerAutoRefreshScheduler implements AutoRefreshScheduler {
  Timer? _timer;

  @override
  bool get isActive => _timer?.isActive ?? false;

  @override
  void start(Duration interval, VoidCallback onTick) {
    stop();
    _timer = Timer.periodic(interval, (_) => onTick());
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

class ForegroundAutoRefreshController extends ChangeNotifier
    with WidgetsBindingObserver {
  ForegroundAutoRefreshController({
    required SettingsController settingsController,
    required WebViewAuthController webAuthController,
    required ManualRefreshController manualRefreshController,
    ReloadPageBeforeRefreshUseCase? reloadPageBeforeRefresh,
    ReloadBeforeRefreshPolicy Function()?
    reloadBeforeForegroundAutoRefreshPolicyProvider,
    required EvaluateAutoRefreshEligibility evaluateEligibility,
    required RunForegroundAutoRefresh runForegroundAutoRefresh,
    required AutoRefreshPolicy policy,
    ValueChanged<QuotaSnapshot>? onSnapshotSaved,
    Clock clock = const SystemClock(),
    AutoRefreshScheduler? scheduler,
    AppLifecycleState? initialLifecycleState,
    bool registerLifecycleObserver = true,
  }) : _settingsController = settingsController,
       _webAuthController = webAuthController,
       _manualRefreshController = manualRefreshController,
       _reloadPageBeforeRefresh = reloadPageBeforeRefresh,
       _reloadBeforeForegroundAutoRefreshPolicyProvider =
           reloadBeforeForegroundAutoRefreshPolicyProvider,
       _evaluateEligibility = evaluateEligibility,
       _runForegroundAutoRefresh = runForegroundAutoRefresh,
       _policy = policy,
       _onSnapshotSaved = onSnapshotSaved,
       _clock = clock,
       _scheduler = scheduler ?? TimerAutoRefreshScheduler(),
       _lifecycleState =
           initialLifecycleState ??
           WidgetsBinding.instance.lifecycleState ??
           AppLifecycleState.resumed {
    _state = _stateFromSettings(AutoRefreshState.initial());
    _settingsController.addListener(_handleSettingsChanged);
    _manualRefreshController.addListener(_handleManualRefreshChanged);
    if (registerLifecycleObserver) {
      WidgetsBinding.instance.addObserver(this);
      _registeredLifecycleObserver = true;
    }
    _syncTimerWithLifecycle();
  }

  final SettingsController _settingsController;
  final WebViewAuthController _webAuthController;
  final ManualRefreshController _manualRefreshController;
  final ReloadPageBeforeRefreshUseCase? _reloadPageBeforeRefresh;
  final ReloadBeforeRefreshPolicy Function()?
  _reloadBeforeForegroundAutoRefreshPolicyProvider;
  final EvaluateAutoRefreshEligibility _evaluateEligibility;
  final RunForegroundAutoRefresh _runForegroundAutoRefresh;
  final AutoRefreshPolicy _policy;
  final ValueChanged<QuotaSnapshot>? _onSnapshotSaved;
  final Clock _clock;
  final AutoRefreshScheduler _scheduler;

  late AutoRefreshState _state;
  AppLifecycleState _lifecycleState;
  bool _isCheckingOrRefreshing = false;
  bool _registeredLifecycleObserver = false;
  ReloadCancellationToken? _activeReloadCancellation;

  AutoRefreshState get state => _state;
  AppLifecycleState get lifecycleState => _lifecycleState;
  bool get isForeground => _lifecycleState == AppLifecycleState.resumed;
  bool get timerActive => _scheduler.isActive;
  String get layoutMode => 'expanded-webview-shell-v1';

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      _syncTimerWithLifecycle();
      unawaited(checkNow(reason: 'lifecycle resumed'));
      notifyListeners();
      return;
    }

    _activeReloadCancellation?.cancel();
    _scheduler.stop();
    _state = _state.copyWith(
      status: _state.enabled
          ? AutoRefreshStatus.skippedNotForeground
          : AutoRefreshStatus.disabled,
      isRefreshInProgress: false,
    );
    notifyListeners();
  }

  Future<void> checkNow({String reason = 'foreground timer'}) async {
    final now = _clock.now();
    final syncedState = _stateFromSettings(_state);
    _state = syncedState.copyWith(
      status: AutoRefreshStatus.checkingEligibility,
    );
    notifyListeners();

    final decision = _evaluateEligibility(
      AutoRefreshEligibilityInput(
        enabled: _state.enabled,
        interval: _state.interval,
        isForeground: isForeground,
        hasWebView: _webAuthController.isReady,
        isWebViewReady: _webAuthController.isReady,
        currentUrl: _webAuthController.currentUrl,
        isPageLoading: _webAuthController.isLoading,
        isRefreshInProgress:
            _isCheckingOrRefreshing || _manualRefreshController.isBusy,
        lastSuccessAt: _state.lastSuccessAt,
        cooldownUntil: _state.cooldownUntil,
        now: now,
      ),
    );

    if (!decision.isEligible) {
      _state = _state.copyWith(
        status: decision.status,
        nextEligibleAt: decision.nextEligibleAt,
        isRefreshInProgress: false,
      );
      _syncTimerWithLifecycle();
      notifyListeners();
      return;
    }

    _isCheckingOrRefreshing = true;
    _state = _state.copyWith(
      status: AutoRefreshStatus.refreshing,
      lastAttemptAt: now,
      isRefreshInProgress: true,
      clearLastError: true,
    );
    notifyListeners();

    try {
      final reloadPolicy =
          _reloadBeforeForegroundAutoRefreshPolicyProvider?.call() ??
          _settingsController.foregroundAutoReloadBeforeRefreshPolicy;
      final reloadUseCase = _reloadPageBeforeRefresh;
      if (reloadUseCase != null && reloadPolicy.enabled) {
        final cancellation = ReloadCancellationToken();
        _activeReloadCancellation = cancellation;
        final reloadResult = await reloadUseCase(
          policy: reloadPolicy,
          isRefreshInProgress: _manualRefreshController.isBusy,
          cancellationSignal: cancellation,
        );
        _activeReloadCancellation = null;
        if (!reloadResult.allowsExtraction) {
          final failedAt = reloadResult.finishedAt ?? _clock.now();
          final status = isForeground
              ? AutoRefreshStatus.failed
              : AutoRefreshStatus.skippedNotForeground;
          _state = _state.copyWith(
            status: status,
            cooldownUntil: status == AutoRefreshStatus.failed
                ? _policy.cooldownUntil(failedAt)
                : null,
            nextEligibleAt: status == AutoRefreshStatus.failed
                ? _policy.cooldownUntil(failedAt)
                : _state.nextEligibleAt,
            lastError: _errorForReloadResult(reloadResult),
            isRefreshInProgress: false,
          );
          return;
        }
        if (!isForeground) {
          _state = _state.copyWith(
            status: AutoRefreshStatus.skippedNotForeground,
            nextEligibleAt: _policy.nextEligibleAt(
              lastSuccessAt: _state.lastSuccessAt,
              interval: _state.interval,
            ),
            lastError:
                'Foreground auto refresh cancelled before extraction because the app left foreground.',
            isRefreshInProgress: false,
          );
          _activeReloadCancellation = null;
          return;
        }
      }

      final result = await _runForegroundAutoRefresh(
        ManualRefreshPageState(
          currentUrl: _webAuthController.currentUrl,
          pageTitle: _webAuthController.pageTitle,
          isLoading: _webAuthController.isLoading,
          isReady: _webAuthController.isReady,
        ),
      );
      final manualResult = result.manualRefreshResult;
      final successAt = manualResult.finishedAt ?? _clock.now();
      if (result.savedSnapshot != null) {
        _onSnapshotSaved?.call(result.savedSnapshot!);
      }

      if (_isSuccessfulManualResult(
        manualResult.status,
        result.hasSuccessfulCandidate,
      )) {
        _state = _state.copyWith(
          status: AutoRefreshStatus.success,
          lastSuccessAt: successAt,
          nextEligibleAt: _policy.nextEligibleAt(
            lastSuccessAt: successAt,
            interval: _state.interval,
          ),
          clearCooldownUntil: true,
          clearLastError: true,
          isRefreshInProgress: false,
        );
      } else {
        _state = _state.copyWith(
          status: AutoRefreshStatus.failed,
          cooldownUntil: _policy.cooldownUntil(successAt),
          nextEligibleAt: _policy.cooldownUntil(successAt),
          lastError: _errorForManualResult(manualResult),
          isRefreshInProgress: false,
        );
      }
    } on Object catch (error) {
      final failedAt = _clock.now();
      _state = _state.copyWith(
        status: AutoRefreshStatus.failed,
        cooldownUntil: _policy.cooldownUntil(failedAt),
        nextEligibleAt: _policy.cooldownUntil(failedAt),
        lastError: SensitiveDataPolicy.sanitizeLogText(error.toString()),
        isRefreshInProgress: false,
      );
    } finally {
      _activeReloadCancellation = null;
      _isCheckingOrRefreshing = false;
      _syncTimerWithLifecycle();
      notifyListeners();
    }
  }

  void _handleSettingsChanged() {
    _state = _stateFromSettings(_state);
    if (!_state.enabled) {
      _state = _state.copyWith(status: AutoRefreshStatus.disabled);
    }
    _syncTimerWithLifecycle();
    notifyListeners();
  }

  void _handleManualRefreshChanged() {
    _state = _state.copyWith(
      isRefreshInProgress:
          _isCheckingOrRefreshing || _manualRefreshController.isBusy,
    );
    notifyListeners();
  }

  AutoRefreshState _stateFromSettings(AutoRefreshState current) {
    final enabled =
        _settingsController.autoRefreshEnabled &&
        !_settingsController.refreshInterval.isOff;
    final status = enabled
        ? (current.status == AutoRefreshStatus.disabled
              ? AutoRefreshStatus.idle
              : current.status)
        : AutoRefreshStatus.disabled;
    return current.copyWith(
      enabled: enabled,
      interval: _settingsController.refreshInterval,
      status: status,
      nextEligibleAt: enabled
          ? _policy.nextEligibleAt(
              lastSuccessAt: current.lastSuccessAt,
              interval: _settingsController.refreshInterval,
            )
          : null,
      clearNextEligibleAt: !enabled,
      isRefreshInProgress:
          _isCheckingOrRefreshing || _manualRefreshController.isBusy,
    );
  }

  void _syncTimerWithLifecycle() {
    if (_state.enabled && isForeground) {
      if (!_scheduler.isActive) {
        _scheduler.start(
          _policy.checkInterval,
          () => unawaited(checkNow(reason: 'foreground timer')),
        );
      }
      return;
    }
    _scheduler.stop();
  }

  bool _isSuccessfulManualResult(
    ManualRefreshStatus status,
    bool hasSuccessfulCandidate,
  ) {
    return status == ManualRefreshStatus.saved ||
        (status == ManualRefreshStatus.awaitingUserConfirmation &&
            hasSuccessfulCandidate);
  }

  String _errorForManualResult(ManualRefreshResult manualResult) {
    final errors = manualResult.errors;
    if (errors.isEmpty) {
      return 'Foreground auto refresh did not produce a savable candidate.';
    }
    return SensitiveDataPolicy.sanitizeLogText(errors.join(' | '));
  }

  String _errorForReloadResult(ReloadBeforeRefreshResult reloadResult) {
    final errors = reloadResult.errors;
    if (errors.isEmpty) {
      return 'Reload before foreground auto refresh stopped: ${reloadResult.status.label}.';
    }
    return SensitiveDataPolicy.sanitizeLogText(errors.join(' | '));
  }

  @override
  void dispose() {
    _scheduler.stop();
    _settingsController.removeListener(_handleSettingsChanged);
    _manualRefreshController.removeListener(_handleManualRefreshChanged);
    if (_registeredLifecycleObserver) {
      WidgetsBinding.instance.removeObserver(this);
      _registeredLifecycleObserver = false;
    }
    super.dispose();
  }
}
