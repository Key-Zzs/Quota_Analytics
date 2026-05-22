import 'package:quota_analytics/app.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/quota/data/datasources/mock_quota_datasource.dart';
import 'package:quota_analytics/features/quota/data/repositories/mock_quota_repository.dart';
import 'package:quota_analytics/features/settings/data/mock_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('quota home page displays mock quota data', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('5-hour window'), findsOneWidget);
    expect(find.text('Weekly window'), findsOneWidget);
    expect(find.textContaining('Stage 1 Mock Mode'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Mock GPT Account'), findsOneWidget);
  });

  testWidgets('refresh keeps the quota home page usable', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Refresh mock quota'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('5-hour window'), findsOneWidget);
    expect(find.text('Weekly window'), findsOneWidget);
    expect(find.textContaining('Stage 1 Mock Mode'), findsOneWidget);
  });
}

Widget _buildApp() {
  return QuotaAnalyticsApp(
    quotaRepository: MockQuotaRepository(
      MockQuotaDataSource(
        clock: _TickingClock(DateTime.utc(2026, 1, 1, 12)),
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
