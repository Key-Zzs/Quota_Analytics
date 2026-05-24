import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/refresh/data/services/page_load_waiter.dart';
import 'package:quota_analytics/features/refresh/data/services/webview_reload_service.dart';
import 'package:quota_analytics/features/refresh/domain/entities/reload_before_refresh_policy.dart';
import 'package:quota_analytics/features/refresh/domain/entities/reload_before_refresh_result.dart';
import 'package:quota_analytics/features/refresh/domain/entities/reload_before_refresh_status.dart';
import 'package:quota_analytics/features/refresh/domain/usecases/reload_page_before_refresh.dart';

void main() {
  test('safe URL + reload success + page finished -> completed', () async {
    final service = _FakeWebViewReloadService();
    final result = await _useCase(service)(
      policy: _policy(),
      isRefreshInProgress: false,
    );

    expect(result.status, ReloadBeforeRefreshStatus.completed);
    expect(result.allowsExtraction, isTrue);
    expect(service.reloadCalls, 1);
    expect(
      result.sanitizedUrl,
      'https://chatgpt.com/codex/cloud/settings/analytics',
    );
  });

  test('unsafe HTTP URL -> blockedUnsafeUrl', () async {
    final service = _FakeWebViewReloadService(
      currentUrl: 'http://chatgpt.com/codex/cloud/settings/analytics?x=secret',
    );

    final result = await _useCase(service)(
      policy: _policy(),
      isRefreshInProgress: false,
    );

    expect(result.status, ReloadBeforeRefreshStatus.blockedUnsafeUrl);
    expect(
      result.sanitizedUrl,
      'http://chatgpt.com/codex/cloud/settings/analytics',
    );
    expect(service.reloadCalls, 0);
  });

  test('unknown host -> blockedUnsafeUrl', () async {
    final service = _FakeWebViewReloadService(
      currentUrl: 'https://example.com',
    );

    final result = await _useCase(service)(
      policy: _policy(),
      isRefreshInProgress: false,
    );

    expect(result.status, ReloadBeforeRefreshStatus.blockedUnsafeUrl);
    expect(service.reloadCalls, 0);
  });

  test('no WebView -> blockedNoWebView', () async {
    final service = _FakeWebViewReloadService(hasWebView: false);

    final result = await _useCase(service)(
      policy: _policy(),
      isRefreshInProgress: false,
    );

    expect(result.status, ReloadBeforeRefreshStatus.blockedNoWebView);
    expect(service.reloadCalls, 0);
  });

  test('page already loading -> blockedPageLoading', () async {
    final service = _FakeWebViewReloadService(isPageLoading: true);

    final result = await _useCase(service)(
      policy: _policy(),
      isRefreshInProgress: false,
    );

    expect(result.status, ReloadBeforeRefreshStatus.blockedPageLoading);
    expect(service.reloadCalls, 0);
  });

  test('reload timeout -> timeout', () async {
    final service = _FakeWebViewReloadService(autoFinish: false);

    final result = await _useCase(service)(
      policy: _policy(timeout: const Duration(milliseconds: 5)),
      isRefreshInProgress: false,
    );

    expect(result.status, ReloadBeforeRefreshStatus.timeout);
    expect(service.reloadCalls, 1);
  });

  test('reload throws -> failed', () async {
    final service = _FakeWebViewReloadService(throwOnReload: true);

    final result = await _useCase(service)(
      policy: _policy(),
      isRefreshInProgress: false,
    );

    expect(result.status, ReloadBeforeRefreshStatus.failed);
    expect(result.errors.join(' '), contains('Reload failed'));
  });

  test('app paused during wait -> cancelled', () async {
    final service = _FakeWebViewReloadService(autoFinish: false);
    final token = ReloadCancellationToken();
    final future = _useCase(service)(
      policy: _policy(timeout: const Duration(milliseconds: 80)),
      isRefreshInProgress: false,
      cancellationSignal: token,
    );

    token.cancel();

    final result = await future;
    expect(result.status, ReloadBeforeRefreshStatus.cancelled);
  });

  test('cooldown active -> blockedCooldown', () async {
    final service = _FakeWebViewReloadService();
    final useCase = _useCase(service);

    final first = await useCase(
      policy: _policy(cooldown: const Duration(seconds: 1)),
      isRefreshInProgress: false,
    );
    final second = await useCase(
      policy: _policy(cooldown: const Duration(seconds: 1)),
      isRefreshInProgress: false,
    );

    expect(first.status, ReloadBeforeRefreshStatus.completed);
    expect(second.status, ReloadBeforeRefreshStatus.blockedCooldown);
    expect(service.reloadCalls, 1);
  });

  test('already refreshing -> blockedAlreadyRefreshing', () async {
    final service = _FakeWebViewReloadService();

    final result = await _useCase(service)(
      policy: _policy(),
      isRefreshInProgress: true,
    );

    expect(result.status, ReloadBeforeRefreshStatus.blockedAlreadyRefreshing);
    expect(service.reloadCalls, 0);
  });

  test('reload success then URL becomes login -> loginRequired', () async {
    final service = _FakeWebViewReloadService(
      urlAfterReload: 'https://chatgpt.com/auth/login?token=secret',
    );

    final result = await _useCase(service)(
      policy: _policy(),
      isRefreshInProgress: false,
    );

    expect(result.status, ReloadBeforeRefreshStatus.loginRequired);
    expect(result.sanitizedUrl, 'https://chatgpt.com/auth/login');
    expect(result.sanitizedUrl, isNot(contains('secret')));
  });
}

ReloadPageBeforeRefreshUseCase _useCase(_FakeWebViewReloadService service) {
  return ReloadPageBeforeRefreshUseCase(
    reloadService: service,
    pageLoadWaiter: const PageLoadWaiter(),
    clock: const SystemClock(),
  );
}

ReloadBeforeRefreshPolicy _policy({
  Duration timeout = const Duration(milliseconds: 80),
  Duration cooldown = const Duration(milliseconds: 20),
}) {
  return ReloadBeforeRefreshPolicy(
    enabled: true,
    reloadTimeout: timeout,
    pageSettleDelay: const Duration(milliseconds: 1),
    reloadCooldown: cooldown,
  );
}

class _FakeWebViewReloadService extends ChangeNotifier
    implements WebViewReloadService {
  _FakeWebViewReloadService({
    this.hasWebView = true,
    this.currentUrl = 'https://chatgpt.com/codex/cloud/settings/analytics',
    this.isPageLoading = false,
    this.autoFinish = true,
    this.throwOnReload = false,
    this.urlAfterReload,
  });

  @override
  bool hasWebView;

  @override
  String currentUrl;

  @override
  bool isPageLoading;

  final bool autoFinish;
  final bool throwOnReload;
  final String? urlAfterReload;

  @override
  DateTime? lastPageFinishedAt;

  @override
  DateTime? lastWebResourceErrorAt;

  @override
  String? lastWebResourceError;

  int reloadCalls = 0;
  DateTime? recordedReloadStartedAt;
  ReloadBeforeRefreshResult? recordedResult;
  DateTime? recordedCooldownUntil;

  @override
  Future<void> reload() async {
    reloadCalls += 1;
    if (throwOnReload) {
      throw StateError('safe reload failure');
    }
    isPageLoading = true;
    notifyListeners();
    if (!autoFinish) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
    currentUrl = urlAfterReload ?? currentUrl;
    isPageLoading = false;
    lastPageFinishedAt = (recordedReloadStartedAt ?? DateTime.now()).add(
      const Duration(milliseconds: 1),
    );
    notifyListeners();
  }

  @override
  void recordReloadStarted(DateTime startedAt) {
    recordedReloadStartedAt = startedAt;
  }

  @override
  void recordReloadResult(
    ReloadBeforeRefreshResult result, {
    DateTime? cooldownUntil,
  }) {
    recordedResult = result;
    recordedCooldownUntil = cooldownUntil;
  }
}
