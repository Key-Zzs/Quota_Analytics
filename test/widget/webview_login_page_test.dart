import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/app.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/auth/domain/entities/webview_clear_result.dart';
import 'package:quota_analytics/features/auth/domain/repositories/web_auth_repository.dart';
import 'package:quota_analytics/features/auth/presentation/controllers/webview_auth_controller.dart';
import 'package:quota_analytics/features/auth/presentation/pages/webview_login_page.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extracted_page_text.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_safety_status.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_source.dart';
import 'package:quota_analytics/features/extraction/domain/repositories/page_text_extraction_repository.dart';
import 'package:quota_analytics/features/extraction/presentation/controllers/page_text_extraction_controller.dart';
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
            pageTextExtractionController: _buildExtractionController(),
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
    expect(
      find.text(
        'Quota parsing runs locally only after text has been redacted.',
      ),
      findsWidgets,
    );
    expect(find.text('Open login page'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Extract Page Text'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Extract Page Text'), findsOneWidget);
    expect(find.text('Reload'), findsOneWidget);
    expect(find.text('Clear WebView data'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text('Fake WebView'), findsOneWidget);
  });

  testWidgets('Web Login page displays Stage 4 extraction safety notice', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WebViewLoginPage(
            controller: WebViewAuthController(
              repository: _FakeWebAuthRepository(),
            ),
            pageTextExtractionController: _buildExtractionController(),
            webViewBuilder: (context, controller) {
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(
      find.textContaining('local parser for redacted visible text'),
      findsWidgets,
    );
    expect(
      find.text(
        'No cookies, tokens, localStorage, sessionStorage, or HTML are accessed.',
      ),
      findsWidgets,
    );
    expect(
      find.text('Extracted text is redacted and kept local for debugging.'),
      findsWidgets,
    );
  });

  testWidgets('Debug page shows Stage 4 safety status', (tester) async {
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
    expect(find.text('localStorage reading disabled'), findsWidgets);
    expect(find.text('sessionStorage reading disabled'), findsWidgets);
    expect(find.text('HTML extraction disabled'), findsOneWidget);
    expect(find.text('Quota parsing enabled'), findsOneWidget);
    expect(find.text('Background refresh disabled'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Text extraction enabled'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Text extraction enabled'), findsOneWidget);
    expect(find.text('Last extraction safety status'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Quota parser enabled'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Quota parser enabled'), findsOneWidget);
    expect(find.text('Automatic refresh'), findsWidgets);
  });
}

PageTextExtractionController _buildExtractionController() {
  return PageTextExtractionController(repository: _FakeExtractionRepository());
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

class _FakeExtractionRepository implements PageTextExtractionRepository {
  @override
  void attachPageTextReader(CurrentPageTextReader reader) {}

  @override
  Future<void> clearExtractedPageText() async {}

  @override
  Future<ExtractedPageText> extractCurrentPageText() async {
    return ExtractedPageText(
      id: 'manual-webview-1',
      sanitizedUrl: 'https://chatgpt.com/settings',
      pageTitle: 'Settings',
      redactedTextPreview: 'Usage [REDACTED_EMAIL]',
      originalLength: 24,
      redactedLength: 22,
      redactedEmailCount: 1,
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
  Future<ExtractedPageText?> getLastExtractedPageText() async {
    return null;
  }
}
