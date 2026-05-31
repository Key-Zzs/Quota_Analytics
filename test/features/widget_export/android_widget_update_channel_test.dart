import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/widget_export/data/models/widget_snapshot_summary_model.dart';
import 'package:quota_analytics/features/widget_export/data/platform/android_widget_update_channel.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_snapshot_summary.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_update_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('quota_analytics/android_widget');
  final now = DateTime.utc(2026, 5, 26, 10, 30);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('successful update signal', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    final notifier = AndroidWidgetUpdateChannel(
      channel: channel,
      isAndroidProvider: () => true,
      clock: FixedClock(now),
    );

    final result = await notifier.updateWidgets();

    expect(result.status, WidgetUpdateSignalStatus.success);
    expect(result.sentAt, now);
    expect(calls.single.method, 'updateQuotaWidgets');
  });

  test('platform exception is handled safely', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'boom', message: 'failed token=secret');
        });
    final notifier = AndroidWidgetUpdateChannel(
      channel: channel,
      isAndroidProvider: () => true,
      clock: FixedClock(now),
    );

    final result = await notifier.updateWidgets();

    expect(result.status, WidgetUpdateSignalStatus.failed);
    expect(result.safeError, isNot(contains('token=secret')));
    expect(result.safeError, contains('token=<redacted>'));
  });

  test('non-Android is a no-op', () async {
    var called = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          called = true;
          return null;
        });
    final notifier = AndroidWidgetUpdateChannel(
      channel: channel,
      isAndroidProvider: () => false,
      clock: FixedClock(now),
    );

    final result = await notifier.updateWidgets();

    expect(result.status, WidgetUpdateSignalStatus.skipped);
    expect(called, isFalse);
  });

  test('update signal sends no payload', () async {
    Object? arguments;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          arguments = call.arguments;
          return null;
        });
    final notifier = AndroidWidgetUpdateChannel(
      channel: channel,
      isAndroidProvider: () => true,
      clock: FixedClock(now),
    );

    await notifier.updateWidgets();

    expect(arguments, isNull);
  });

  test(
    'summary sync payload contains only display-safe summary JSON',
    () async {
      Map<dynamic, dynamic>? arguments;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            arguments = call.arguments as Map<dynamic, dynamic>;
            return null;
          });
    final notifier = AndroidWidgetUpdateChannel(
      channel: channel,
      isAndroidProvider: () => true,
      clock: FixedClock(now),
    );

      await notifier.syncSummary(_summary(now));

      final summaryJson = arguments?['summaryJson'] as String;
      final decoded = jsonDecode(summaryJson) as Map<String, Object?>;
      expect(decoded.keys, isNot(contains('rawDebugText')));
      expect(decoded.keys, isNot(contains('extractedPageText')));
      expect(decoded.keys, isNot(contains('parserInput')));
      expect(decoded.keys, isNot(contains('cookie')));
      expect(decoded.keys, isNot(contains('token')));
      expect(decoded.keys, isNot(contains('localStorage')));
      expect(decoded.keys, isNot(contains('sessionStorage')));
    },
  );
}

WidgetSnapshotSummary _summary(DateTime now) {
  return WidgetSnapshotSummaryModel(
    schemaVersion: WidgetSnapshotSummary.currentSchemaVersion,
    id: 'snapshot-1',
    fiveHourRemainingRatio: 0.7,
    fiveHourResetText: 'Reset time available',
    fiveHourResetAt: now.add(const Duration(hours: 2)),
    weeklyRemainingRatio: 0.5,
    weeklyResetText: 'Reset time available',
    weeklyResetAt: now.add(const Duration(days: 2)),
    creditsRemaining: 12,
    lastUpdatedAt: now,
    source: 'webViewManualExtraction',
    parserConfidence: 'high',
    isStale: false,
    staleReason: 'fresh',
    displayTitle: 'Quota Analytics',
    displaySubtitle: 'Updated 10:30',
    statusLabel: 'OK',
    errorLabel: null,
    exportedAt: now,
  );
}
