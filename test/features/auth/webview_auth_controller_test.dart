import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/auth/domain/entities/web_auth_navigation_error.dart';
import 'package:quota_analytics/features/auth/domain/entities/web_auth_status.dart';
import 'package:quota_analytics/features/auth/domain/entities/webview_clear_result.dart';
import 'package:quota_analytics/features/auth/domain/repositories/web_auth_repository.dart';
import 'package:quota_analytics/features/auth/presentation/controllers/webview_auth_controller.dart';

void main() {
  test('initial state is unknown', () {
    final controller = WebViewAuthController(
      repository: _FakeWebAuthRepository(),
      clock: FixedClock(DateTime(2026, 1, 1, 12)),
    );

    expect(controller.authStatus, WebAuthStatus.unknown);
    expect(controller.currentUrl, 'none');
    expect(controller.loadingProgress, 0);
    expect(controller.lastError, isNull);
  });

  test('onPageStarted updates loading state and sanitized URL', () {
    final controller = WebViewAuthController(
      repository: _FakeWebAuthRepository(),
      clock: FixedClock(DateTime(2026, 1, 1, 12)),
    );

    controller.onPageStarted('https://chatgpt.com/auth/login?token=secret#x');

    expect(controller.isLoading, isTrue);
    expect(controller.loadingProgress, 0);
    expect(controller.currentUrl, 'https://chatgpt.com/auth/login');
    expect(controller.currentUrl, isNot(contains('secret')));
    expect(controller.authStatus, WebAuthStatus.loggedOut);
  });

  test('onPageFinished updates title, URL, and loading state', () async {
    final repository = _FakeWebAuthRepository(title: 'Settings');
    final controller = WebViewAuthController(
      repository: repository,
      clock: FixedClock(DateTime(2026, 1, 1, 12)),
    );

    await controller.onPageFinished('https://chatgpt.com/settings?state=abc#x');

    expect(controller.isLoading, isFalse);
    expect(controller.loadingProgress, 100);
    expect(controller.currentUrl, 'https://chatgpt.com/settings');
    expect(controller.pageTitle, 'Settings');
    expect(controller.authStatus, WebAuthStatus.maybeLoggedIn);
  });

  test('onWebResourceError records safe error state', () {
    final controller = WebViewAuthController(
      repository: _FakeWebAuthRepository(),
      clock: FixedClock(DateTime(2026, 1, 1, 12)),
    );

    controller.onWebResourceError(
      const WebAuthNavigationError(
        description: 'network error at https://example.com/path?token=secret#x',
        errorCode: -2,
        errorType: 'hostLookup',
      ),
    );

    expect(controller.authStatus, WebAuthStatus.error);
    expect(controller.isLoading, isFalse);
    expect(controller.lastError, contains('hostLookup'));
    expect(controller.lastError, isNot(contains('secret')));
    expect(controller.lastError, isNot(contains('#')));
  });

  test('clearWebViewData updates controller state', () async {
    final repository = _FakeWebAuthRepository();
    final controller = WebViewAuthController(
      repository: repository,
      clock: FixedClock(DateTime(2026, 1, 1, 12)),
    );

    await controller.clearWebViewData();

    expect(repository.clearCount, 1);
    expect(controller.lastDataClearTime, DateTime(2026, 1, 1, 12));
    expect(controller.lastClearResult?.completed, isTrue);
    expect(controller.message, contains('WebView cache'));
  });
}

class _FakeWebAuthRepository implements WebAuthRepository {
  _FakeWebAuthRepository({this.title = 'none'});

  final String title;
  int clearCount = 0;

  @override
  Future<bool> canGoBack() async => false;

  @override
  Future<bool> canGoForward() async => false;

  @override
  Future<WebViewClearResult> clearWebViewData() async {
    clearCount += 1;
    return const WebViewClearResult(
      cacheCleared: true,
      localStorageCleared: true,
      cookiesCleared: true,
    );
  }

  @override
  Future<String?> currentUrl() async => 'https://chatgpt.com/settings';

  @override
  Future<void> goBack() async {}

  @override
  Future<void> goForward() async {}

  @override
  Future<void> load(Uri uri) async {}

  @override
  Future<String?> pageTitle() async => title;

  @override
  Future<void> reload() async {}
}
