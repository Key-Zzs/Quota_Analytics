import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/app.dart';
import 'package:quota_analytics/core/storage/local_storage_keys.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/quota/data/datasources/mock_quota_datasource.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';
import 'package:quota_analytics/features/quota/data/repositories/mock_quota_repository.dart';
import 'package:quota_analytics/features/settings/data/mock_settings_repository.dart';
import 'package:quota_analytics/features/settings/data/models/app_settings_model.dart';
import 'package:quota_analytics/features/settings/domain/entities/app_settings.dart';
import 'package:quota_analytics/features/settings/domain/entities/refresh_interval.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('quota home page displays mock quota data', (tester) async {
    await tester.pumpWidget(_buildInjectedApp());
    await tester.pumpAndSettle();

    expect(find.text('5-hour window'), findsOneWidget);
    expect(find.text('Weekly window'), findsOneWidget);
    expect(find.textContaining('Stage 2 Mock Mode'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
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

  testWidgets('refresh updates the displayed last updated time', (
    tester,
  ) async {
    await tester.pumpWidget(_buildInjectedApp());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('2026-01-01 12:00:00'), findsOneWidget);

    await tester.tap(find.byTooltip('Refresh mock quota'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('2026-01-01 12:01:00'), findsOneWidget);
  });

  testWidgets('Settings page displays and updates refresh interval', (
    tester,
  ) async {
    await tester.pumpWidget(_buildInjectedApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Off'), findsWidgets);

    await tester.tap(find.text('Off').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 minutes').last);
    await tester.pumpAndSettle();

    expect(find.text('Auto refresh: On'), findsOneWidget);
    expect(find.text('Interval: 30 minutes'), findsOneWidget);

    await tester.tap(find.text('Save settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings saved'), findsOneWidget);
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
        updatedAt: DateTime(2026, 1, 1, 13),
      ),
    );
    SharedPreferences.setMockInitialValues({
      LocalStorageKeys.quotaLatestSnapshot: jsonEncode(snapshot.toJson()),
      LocalStorageKeys.quotaSnapshotHistory: jsonEncode([snapshot.toJson()]),
      LocalStorageKeys.appSettings: jsonEncode(settings.toJson()),
    });

    await tester.pumpWidget(
      QuotaAnalyticsApp(clock: FixedClock(DateTime(2026, 1, 2, 12))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Debug'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('60 minutes'), findsOneWidget);

    await tester.ensureVisible(find.text('Clear local data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear local data'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Local data cleared'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
  });
}

Widget _buildInjectedApp() {
  return QuotaAnalyticsApp(
    quotaRepository: MockQuotaRepository(
      MockQuotaDataSource(
        clock: _TickingClock(DateTime(2026, 1, 1, 12)),
        refreshDelay: Duration.zero,
      ),
    ),
    settingsRepository: MockSettingsRepository(),
  );
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
