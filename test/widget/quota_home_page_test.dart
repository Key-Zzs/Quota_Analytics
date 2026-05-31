import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/app.dart';
import 'package:quota_analytics/core/storage/local_storage_keys.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/extraction/data/models/extracted_page_text_model.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_safety_status.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_source.dart';
import 'package:quota_analytics/features/quota/data/datasources/mock_quota_datasource.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';
import 'package:quota_analytics/features/quota/data/repositories/mock_quota_repository.dart';
import 'package:quota_analytics/features/settings/data/mock_settings_repository.dart';
import 'package:quota_analytics/features/settings/data/models/app_settings_model.dart';
import 'package:quota_analytics/features/settings/domain/entities/app_settings.dart';
import 'package:quota_analytics/features/settings/domain/entities/refresh_interval.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_policy.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_launch_action.dart';
import 'package:quota_analytics/features/widget_export/domain/repositories/widget_launch_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('quota home page displays mock quota data', (tester) async {
    await tester.pumpWidget(_buildInjectedApp());
    await tester.pumpAndSettle();

    expect(find.text('5-hour window'), findsOneWidget);
    expect(find.textContaining('Stage 11:'), findsOneWidget);
    expect(find.text('Go to Web Refresh'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Mock GPT Account'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Mock GPT Account'), findsOneWidget);
  });

  testWidgets('home page can display a locally cached snapshot', (
    tester,
  ) async {
    final cached = QuotaSnapshotModel.mock(
      capturedAt: DateTime(2026, 1, 1, 12),
      variant: 8,
    );
    SharedPreferences.setMockInitialValues({
      LocalStorageKeys.quotaLatestSnapshot: jsonEncode(cached.toJson()),
    });

    await tester.pumpWidget(
      QuotaAnalyticsApp(clock: FixedClock(DateTime(2026, 1, 2, 12))),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Loaded from local cache'), findsOneWidget);
    expect(find.text('true'), findsOneWidget);
    expect(find.text('Mock GPT Account'), findsOneWidget);
  });

  testWidgets('quota refresh action uses the usage-page refresh entry point', (
    tester,
  ) async {
    await tester.pumpWidget(_buildInjectedApp());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Refresh usage page'), findsOneWidget);
    expect(find.byTooltip('Refresh mock quota'), findsNothing);
  });

  testWidgets('widget refresh launch opens quota page with visible prompt', (
    tester,
  ) async {
    final launchChannel = _FakeWidgetLaunchChannel();
    await tester.pumpWidget(
      _buildInjectedApp(widgetLaunchChannel: launchChannel),
    );
    await tester.pumpAndSettle();

    launchChannel.emit(
      const WidgetLaunchAction(
        source: WidgetLaunchSource.widget,
        target: WidgetLaunchTarget.refreshUsagePage,
        action: WidgetLaunchIntentAction.openRefreshFlow,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Go to Web Refresh'), findsOneWidget);
    expect(
      find.text('Opened from widget. Tap Refresh usage page to update.'),
      findsOneWidget,
    );
  });

  testWidgets('Settings page displays and updates refresh interval', (
    tester,
  ) async {
    await tester.pumpWidget(_buildInjectedApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Foreground Auto Refresh'), findsOneWidget);
    expect(find.text('Foreground only'), findsOneWidget);
    expect(find.text('No background refresh'), findsOneWidget);
    expect(find.text('No automatic login'), findsOneWidget);
    expect(find.text('Uses current WebView page only'), findsOneWidget);
    expect(
      find.text('Reload page before foreground auto refresh'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Only works while the app is in the foreground.'),
      findsOneWidget,
    );
    expect(find.text('Off'), findsWidgets);

    await tester.tap(find.byType(DropdownButtonFormField<RefreshInterval>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 minutes').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Persisted settings'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Auto refresh: On'), findsOneWidget);
    expect(find.text('Interval: 30 minutes'), findsOneWidget);
    expect(find.text('Reload before manual refresh: On'), findsOneWidget);
    expect(
      find.text('Reload before foreground auto refresh: Off'),
      findsOneWidget,
    );
    expect(
      find.text('Manual refresh auto-save high confidence: Off'),
      findsOneWidget,
    );

    await tester.tap(find.text('Save settings').first);
    await tester.pumpAndSettle();

    expect(find.text('Settings saved'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Android Widget'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Android Widget'), findsOneWidget);
    expect(
      find.text('Widget does not refresh web page in background.'),
      findsOneWidget,
    );
  });

  testWidgets('Debug page displays persisted history count', (tester) async {
    final first = QuotaSnapshotModel.mock(
      capturedAt: DateTime(2026, 1, 1, 12),
      variant: 1,
    );
    final second = QuotaSnapshotModel.mock(
      capturedAt: DateTime(2026, 1, 1, 12, 15),
      variant: 2,
    );
    SharedPreferences.setMockInitialValues({
      LocalStorageKeys.quotaSnapshotHistory: jsonEncode([
        first.toJson(),
        second.toJson(),
      ]),
    });

    await tester.pumpWidget(
      QuotaAnalyticsApp(clock: FixedClock(DateTime(2026, 1, 2, 12))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Debug'));
    await tester.pumpAndSettle();

    expect(find.text('History count'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Clear local data resets persisted UI state', (tester) async {
    final snapshot = QuotaSnapshotModel.mock(
      capturedAt: DateTime(2026, 1, 1, 12),
      variant: 4,
    );
    final settings = AppSettingsModel.fromEntity(
      AppSettings(
        autoRefreshEnabled: true,
        refreshInterval: RefreshInterval.sixtyMinutes,
        manualRefreshPolicy: const ManualRefreshPolicy(
          autoSaveHighConfidence: true,
          requireConfirmationForMediumConfidence: true,
          allowLowConfidenceSave: false,
        ),
        updatedAt: DateTime(2026, 1, 1, 13),
      ),
    );
    final extraction = ExtractedPageTextModel(
      id: 'manual-webview-1',
      sanitizedUrl: 'https://chatgpt.com/settings',
      pageTitle: 'Settings',
      redactedTextPreview: 'Cached [REDACTED_EMAIL]',
      originalLength: 24,
      redactedLength: 24,
      redactedEmailCount: 1,
      redactedTokenCount: 0,
      redactedApiKeyCount: 0,
      redactedSecretCount: 0,
      truncated: false,
      extractedAt: DateTime(2026, 1, 1, 14),
      source: ExtractionSource.webViewManual,
      safetyStatus: ExtractionSafetyStatus.allowed,
    );
    SharedPreferences.setMockInitialValues({
      LocalStorageKeys.quotaLatestSnapshot: jsonEncode(snapshot.toJson()),
      LocalStorageKeys.quotaSnapshotHistory: jsonEncode([snapshot.toJson()]),
      LocalStorageKeys.appSettings: jsonEncode(settings.toJson()),
      LocalStorageKeys.extractedPageText: jsonEncode(extraction.toJson()),
    });

    await tester.pumpWidget(
      QuotaAnalyticsApp(clock: FixedClock(DateTime(2026, 1, 2, 12))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Debug'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('60 minutes'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cached [REDACTED_EMAIL]'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Cached [REDACTED_EMAIL]'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Clear local data'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear local data'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Local data cleared'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    expect(find.text('Cached [REDACTED_EMAIL]'), findsNothing);
  });
}

Widget _buildInjectedApp({WidgetLaunchChannel? widgetLaunchChannel}) {
  return QuotaAnalyticsApp(
    quotaRepository: MockQuotaRepository(
      MockQuotaDataSource(
        clock: _TickingClock(DateTime(2026, 1, 1, 12)),
        refreshDelay: Duration.zero,
      ),
    ),
    settingsRepository: MockSettingsRepository(),
    widgetLaunchChannel: widgetLaunchChannel,
  );
}

class _FakeWidgetLaunchChannel implements WidgetLaunchChannel {
  _FakeWidgetLaunchChannel({this.initialAction});

  final WidgetLaunchAction? initialAction;
  WidgetLaunchActionHandler? _handler;

  @override
  Future<WidgetLaunchAction?> consumeInitialLaunchAction() async {
    return initialAction;
  }

  @override
  void setLaunchActionHandler(WidgetLaunchActionHandler? handler) {
    _handler = handler;
  }

  void emit(WidgetLaunchAction action) {
    _handler?.call(action);
  }
}

class _TickingClock implements Clock {
  _TickingClock(this._current);

  DateTime _current;

  @override
  DateTime now() {
    final value = _current;
    _current = _current.add(const Duration(minutes: 1));
    return value;
  }
}
