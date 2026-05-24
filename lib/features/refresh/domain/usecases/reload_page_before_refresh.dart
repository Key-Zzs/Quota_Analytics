import '../../../../core/security/allowed_web_hosts.dart';
import '../../../../core/security/sensitive_data_policy.dart';
import '../../../../core/time/clock.dart';
import '../../data/services/page_load_waiter.dart';
import '../../data/services/webview_reload_service.dart';
import '../entities/reload_before_refresh_policy.dart';
import '../entities/reload_before_refresh_result.dart';
import '../entities/reload_before_refresh_status.dart';

typedef ReloadBeforeRefreshProgressCallback =
    void Function(ReloadBeforeRefreshResult result);

class ReloadPageBeforeRefreshUseCase {
  ReloadPageBeforeRefreshUseCase({
    required WebViewReloadService reloadService,
    required PageLoadWaiter pageLoadWaiter,
    required Clock clock,
  }) : _reloadService = reloadService,
       _pageLoadWaiter = pageLoadWaiter,
       _clock = clock;

  final WebViewReloadService _reloadService;
  final PageLoadWaiter _pageLoadWaiter;
  final Clock _clock;

  bool _isReloading = false;
  int _consecutiveFailures = 0;
  DateTime? _cooldownUntil;
  ReloadBeforeRefreshResult? _lastResult;

  bool get isReloading => _isReloading;
  int get consecutiveFailures => _consecutiveFailures;
  DateTime? get cooldownUntil => _cooldownUntil;
  ReloadBeforeRefreshResult? get lastResult => _lastResult;

  Future<ReloadBeforeRefreshResult> call({
    required ReloadBeforeRefreshPolicy policy,
    required bool isRefreshInProgress,
    ReloadCancellationSignal? cancellationSignal,
    ReloadBeforeRefreshProgressCallback? onProgress,
  }) async {
    final startedAt = _clock.now();

    ReloadBeforeRefreshResult emit(
      ReloadBeforeRefreshStatus status, {
      String? sanitizedUrl,
      List<String> warnings = const [],
      List<String> errors = const [],
      bool terminal = false,
    }) {
      final result = ReloadBeforeRefreshResult(
        status: status,
        startedAt: startedAt,
        finishedAt: terminal ? _clock.now() : null,
        sanitizedUrl: sanitizedUrl ?? 'none',
        warnings: warnings,
        errors: errors.map(SensitiveDataPolicy.sanitizeLogText).toList(),
      );
      _lastResult = result;
      onProgress?.call(result);
      if (terminal) {
        _reloadService.recordReloadResult(
          result,
          cooldownUntil: _cooldownUntil,
        );
      }
      return result;
    }

    if (!policy.enabled) {
      return emit(ReloadBeforeRefreshStatus.disabled, terminal: true);
    }

    if (cancellationSignal?.isCancelled ?? false) {
      return _recordFailure(
        emit(ReloadBeforeRefreshStatus.cancelled, terminal: true),
        policy: policy,
        usesCooldown: false,
      );
    }

    if (!_reloadService.hasWebView) {
      return emit(
        ReloadBeforeRefreshStatus.blockedNoWebView,
        errors: const ['WebView controller is not ready.'],
        terminal: true,
      );
    }

    if (_isReloading || isRefreshInProgress) {
      return emit(
        ReloadBeforeRefreshStatus.blockedAlreadyRefreshing,
        sanitizedUrl: _safeUrl(),
        errors: const ['Another refresh or reload is already in progress.'],
        terminal: true,
      );
    }

    final now = _clock.now();
    if (_cooldownUntil != null && now.isBefore(_cooldownUntil!)) {
      return emit(
        ReloadBeforeRefreshStatus.blockedCooldown,
        sanitizedUrl: _safeUrl(),
        warnings: ['Reload cooldown is active until $_cooldownUntil.'],
        terminal: true,
      );
    }

    final initialDecision = AllowedWebHosts.evaluate(_reloadService.currentUrl);
    emit(
      ReloadBeforeRefreshStatus.checkingUrl,
      sanitizedUrl: initialDecision.sanitizedUrl,
    );

    if (!initialDecision.isAllowed) {
      return emit(
        ReloadBeforeRefreshStatus.blockedUnsafeUrl,
        sanitizedUrl: initialDecision.sanitizedUrl,
        errors: [initialDecision.message],
        terminal: true,
      );
    }

    if (_reloadService.isPageLoading) {
      return emit(
        ReloadBeforeRefreshStatus.blockedPageLoading,
        sanitizedUrl: initialDecision.sanitizedUrl,
        errors: const ['Current WebView page is still loading.'],
        terminal: true,
      );
    }

    _isReloading = true;
    _reloadService.recordReloadStarted(startedAt);
    emit(
      ReloadBeforeRefreshStatus.reloading,
      sanitizedUrl: initialDecision.sanitizedUrl,
    );

    try {
      await _reloadService.reload();
    } on Object catch (error) {
      return _recordFailure(
        emit(
          ReloadBeforeRefreshStatus.failed,
          sanitizedUrl: initialDecision.sanitizedUrl,
          errors: [
            'Reload failed: ${SensitiveDataPolicy.sanitizeLogText(error.toString())}',
          ],
          terminal: true,
        ),
        policy: policy,
      );
    }

    emit(
      ReloadBeforeRefreshStatus.waitingForPageFinished,
      sanitizedUrl: initialDecision.sanitizedUrl,
    );

    final waitResult = await _pageLoadWaiter.waitForPageFinished(
      pageState: _reloadService,
      reloadStartedAt: startedAt,
      timeout: policy.reloadTimeout,
      settleDelay: policy.pageSettleDelay,
      cancellationSignal: cancellationSignal,
      onSettleStarted: () {
        emit(
          ReloadBeforeRefreshStatus.waitingForSettleDelay,
          sanitizedUrl: _safeUrl(),
        );
      },
    );

    if (waitResult.status == PageLoadWaitStatus.cancelled) {
      return _recordFailure(
        emit(
          ReloadBeforeRefreshStatus.cancelled,
          sanitizedUrl: _safeUrl(),
          warnings: const [
            'Reload was cancelled because the app left foreground.',
          ],
          terminal: true,
        ),
        policy: policy,
        usesCooldown: false,
      );
    }
    if (waitResult.status == PageLoadWaitStatus.timeout) {
      return _recordFailure(
        emit(
          ReloadBeforeRefreshStatus.timeout,
          sanitizedUrl: _safeUrl(),
          errors: const ['Reload timed out before the page finished loading.'],
          terminal: true,
        ),
        policy: policy,
      );
    }
    if (waitResult.status == PageLoadWaitStatus.failed) {
      return _recordFailure(
        emit(
          ReloadBeforeRefreshStatus.failed,
          sanitizedUrl: _safeUrl(),
          errors: [
            waitResult.errorMessage ?? 'Reload failed while loading the page.',
          ],
          terminal: true,
        ),
        policy: policy,
      );
    }

    final finalDecision = AllowedWebHosts.evaluate(_reloadService.currentUrl);
    if (!finalDecision.isAllowed) {
      return _recordFailure(
        emit(
          ReloadBeforeRefreshStatus.blockedUnsafeUrl,
          sanitizedUrl: finalDecision.sanitizedUrl,
          errors: [finalDecision.message],
          terminal: true,
        ),
        policy: policy,
      );
    }

    if (_looksLikeLoginOrAuth(finalDecision.sanitizedUrl)) {
      return _recordFailure(
        emit(
          ReloadBeforeRefreshStatus.loginRequired,
          sanitizedUrl: finalDecision.sanitizedUrl,
          errors: const ['Reload landed on a login or auth page.'],
          terminal: true,
        ),
        policy: policy,
      );
    }

    emit(
      ReloadBeforeRefreshStatus.readyForExtraction,
      sanitizedUrl: finalDecision.sanitizedUrl,
    );
    _consecutiveFailures = 0;
    _cooldownUntil = _clock.now().add(policy.reloadCooldown);
    _isReloading = false;
    return emit(
      ReloadBeforeRefreshStatus.completed,
      sanitizedUrl: finalDecision.sanitizedUrl,
      terminal: true,
    );
  }

  ReloadBeforeRefreshResult _recordFailure(
    ReloadBeforeRefreshResult result, {
    required ReloadBeforeRefreshPolicy policy,
    bool usesCooldown = true,
  }) {
    _isReloading = false;
    if (usesCooldown) {
      _consecutiveFailures += 1;
      final failureCooldown = _clock.now().add(policy.reloadCooldown);
      _cooldownUntil = failureCooldown;
      if (_consecutiveFailures >= policy.maxConsecutiveReloadFailures) {
        _cooldownUntil = failureCooldown.add(policy.reloadCooldown);
      }
    }
    _reloadService.recordReloadResult(result, cooldownUntil: _cooldownUntil);
    return result;
  }

  String _safeUrl() {
    return AllowedWebHosts.evaluate(_reloadService.currentUrl).sanitizedUrl;
  }

  bool _looksLikeLoginOrAuth(String? sanitizedUrl) {
    final value = sanitizedUrl?.toLowerCase() ?? '';
    const markers = ['login', 'log-in', 'signin', 'sign-in', 'auth', 'oauth'];
    return markers.any(value.contains);
  }
}
