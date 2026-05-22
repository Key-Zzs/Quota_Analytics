import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/app.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/auth/domain/entities/webview_clear_result.dart';
import 'package:quota_analytics/features/auth/domain/repositories/web_auth_repository.dart';
import 'package:quota_analytics/features/auth/presentation/controllers/webview_auth_controller.dart';
import 'package:quota_analytics/features/auth/presentation/pages/webview_login_page.dart';
import 'package:quota_analytics/features/quota/data/datasources/mock_quota_datasource.dart';
import 'package:quota_analytics/features/quota/data/repositories/mock_quota_repository.dart';
import 'package:quota_analytics/features/settings/data/mock_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Web Login page shows safety notice and controls', (
    tester,
  ) async {
    final controller = WebViewAuthController(
      repository: _FakeWebAuthRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WebViewLoginPage(
            controller: controller,
            webViewBuilder: (context, controller) {
              return const Center(child: Text('Fake WebView'));
            },
          ),
        ),
      ),
    );

    expect(find.text('Official Web Login'), findsOneWidget);
    expect(
      find.text(
        'You are logging in through the official website inside a WebView.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('This app does not read cookies or tokens.'),
      findsOneWidget,
    );
    expect(find.text('Stage 3 does not extract quota data.'), findsOneWidget);
    expect(find.text('Open login page'), findsOneWidget);
    expect(find.text('Reload'), findsOneWidget);
    expect(find.text('Clear WebView data'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text('Fake WebView'), findsOneWidget);
  });

  testWidgets('Web Login page displays Stage 3 no quota extraction notice', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WebViewLoginPage(
            controller: WebViewAuthController(
              repository: _FakeWebAuthRepository(),
            ),
            webViewBuilder: (context, controller) {
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(find.textContaining('login container only'), findsWidgets);
    expect(find.text('No quota extraction.'), findsOneWidget);
    expect(find.text('Stage 3 does not extract quota data.'), findsOneWidget);
  });

  testWidgets('Debug page shows Stage 3 safety status', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      QuotaAnalyticsApp(
        quotaRepository: MockQuotaRepository(
          MockQuotaDataSource(
            clock: FixedClock(DateTime(2026, 1, 1, 12)),
            refreshDelay: Duration.zero,
          ),
        ),
        settingsRepository: MockSettingsRepository(),
        clock: FixedClock(DateTime(2026, 1, 1, 12)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Debug'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('WebView feature enabled'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('WebView feature enabled'), findsOneWidget);
    expect(find.text('Cookie reading disabled'), findsOneWidget);
    expect(find.text('Token reading disabled'), findsOneWidget);
    expect(find.text('HTML extraction disabled'), findsOneWidget);
    expect(find.text('Quota parsing disabled'), findsOneWidget);
    expect(find.text('Background refresh disabled'), findsOneWidget);
  });
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
  Future<String?> currentUrl() async => null;

  @override
  Future<void> goBack() async {}

  @override
  Future<void> goForward() async {}

  @override
  Future<void> load(Uri uri) async {}

  @override
  Future<String?> pageTitle() async => 'Fake Page';

  @override
  Future<void> reload() async {}
}
