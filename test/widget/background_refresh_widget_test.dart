import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/app.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/quota/data/datasources/mock_quota_datasource.dart';
import 'package:quota_analytics/features/quota/data/repositories/mock_quota_repository.dart';
import 'package:quota_analytics/features/settings/data/mock_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Settings page displays Android Background Refresh section', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Android Background Refresh'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Android Background Refresh'), findsOneWidget);
    expect(find.text('Background refresh mode'), findsOneWidget);
    expect(find.text('Notify only'), findsOneWidget);
    expect(
      find.textContaining('Notification permission status'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Background refresh does not access WebView, cookies, tokens, or page text.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Without an official API or background-safe data source, background mode only sends reminders based on the last saved snapshot.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Debug page displays Stage 8 safety and cooldown state', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Debug'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Stage 8 Background Refresh'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Stage 8 Background Refresh'), findsOneWidget);
    expect(find.textContaining('Last background run status'), findsOneWidget);
    expect(find.text('No hidden WebView background extraction'), findsWidgets);
    expect(
      find.text('No background cookie/token/storage access'),
      findsWidgets,
    );
    expect(
      find.text('No background page text or HTML extraction'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Notification cooldown state'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Notification cooldown state'), findsOneWidget);
    expect(find.text('Run background check now'), findsOneWidget);
  });
}

QuotaAnalyticsApp _buildApp() {
  return QuotaAnalyticsApp(
    quotaRepository: MockQuotaRepository(
      MockQuotaDataSource(
        clock: FixedClock(DateTime(2026, 1, 1, 12)),
        refreshDelay: Duration.zero,
      ),
    ),
    settingsRepository: MockSettingsRepository(),
    clock: FixedClock(DateTime(2026, 1, 1, 12)),
  );
}
