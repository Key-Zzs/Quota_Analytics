import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/storage/local_storage_keys.dart';
import 'package:quota_analytics/core/storage/memory_json_storage.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/background_refresh/data/datasources/local_background_refresh_datasource.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';

void main() {
  test('background snapshot loader strips parser raw debug text', () async {
    final storage = MemoryJsonStorage();
    final snapshot = QuotaSnapshotModel.mock(
      capturedAt: DateTime(2026, 1, 1, 12),
      variant: 1,
    );
    final json = snapshot.toJson()
      ..['accountLabel'] = 'person@example.com'
      ..['rawDebugText'] = 'raw page text with token=secret';
    await storage.writeString(
      LocalStorageKeys.quotaLatestSnapshot,
      jsonEncode(json),
    );

    final dataSource = LocalBackgroundRefreshDataSource(
      storage: storage,
      clock: FixedClock(DateTime(2026, 1, 1, 13)),
    );
    final loaded = await dataSource.loadLatestSnapshotForBackground();

    expect(loaded, isNotNull);
    expect(loaded!.accountLabel, 'Local snapshot');
    expect(loaded.rawDebugText, isNull);
    expect(loaded.fiveHourWindow.remainingRatio, isNotNull);
  });

  test(
    'background failure metadata ignores nested extracted and parser text',
    () async {
      final storage = MemoryJsonStorage();
      await storage.writeString(
        LocalStorageKeys.manualRefreshResult,
        jsonEncode({
          'status': 'parseFailed',
          'startedAt': '2026-01-01T12:00:00.000',
          'finishedAt': '2026-01-01T12:00:05.000',
          'extractedPageText': {
            'redactedTextPreview': 'raw page text should not be used',
          },
          'parseResult': {
            'credits': {'rawText': 'token=secret'},
          },
        }),
      );

      final dataSource = LocalBackgroundRefreshDataSource(
        storage: storage,
        clock: FixedClock(DateTime(2026, 1, 1, 13)),
      );
      final metadata = await dataSource.loadLastRefreshFailureMetadata();

      expect(metadata.failed, isTrue);
      expect(metadata.statusLabel, 'parse failed');
      expect(metadata.occurredAt, DateTime(2026, 1, 1, 12, 0, 5));
    },
  );
}
