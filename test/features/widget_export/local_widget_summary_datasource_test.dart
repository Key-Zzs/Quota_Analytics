import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/storage/local_storage_keys.dart';
import 'package:quota_analytics/core/storage/memory_json_storage.dart';
import 'package:quota_analytics/features/widget_export/data/datasources/local_widget_summary_datasource.dart';
import 'package:quota_analytics/features/widget_export/data/models/widget_snapshot_summary_model.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_export_metadata.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_export_status.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_snapshot_summary.dart';

void main() {
  test('save and load summary', () async {
    final storage = MemoryJsonStorage();
    final dataSource = LocalWidgetSummaryDataSource(storage: storage);
    final summary = _summary();

    await dataSource.saveSummary(summary);
    final loaded = await dataSource.loadSummary();
    final metadata = await dataSource.loadMetadata();

    expect(loaded?.id, summary.id);
    expect(loaded?.schemaVersion, '1');
    expect(metadata.status, WidgetExportStatus.success);
    expect(metadata.lastExportedAt, summary.exportedAt);
    expect(metadata.lastExportError, isNull);
  });

  test('clear summary removes latest summary and records metadata', () async {
    final storage = MemoryJsonStorage();
    final dataSource = LocalWidgetSummaryDataSource(storage: storage);
    final clearedAt = DateTime.utc(2026, 5, 26, 11);

    await dataSource.saveSummary(_summary());
    await dataSource.clearSummary(clearedAt: clearedAt);

    expect(await dataSource.loadSummary(), isNull);
    final metadata = await dataSource.loadMetadata();
    expect(metadata.status, WidgetExportStatus.cleared);
    expect(metadata.lastExportedAt, clearedAt);
  });

  test('corrupted JSON falls back to null and records safe failure', () async {
    final storage = MemoryJsonStorage();
    final dataSource = LocalWidgetSummaryDataSource(storage: storage);
    await storage.writeString(
      LocalStorageKeys.widgetLatestSummaryJson,
      '{bad json',
    );

    final loaded = await dataSource.loadSummary();
    final metadata = await dataSource.loadMetadata();

    expect(loaded, isNull);
    expect(metadata.status, WidgetExportStatus.failed);
    expect(metadata.lastExportError, contains('Invalid widget summary JSON'));
  });

  test('export metadata can be saved and loaded', () async {
    final storage = MemoryJsonStorage();
    final dataSource = LocalWidgetSummaryDataSource(storage: storage);
    final exportedAt = DateTime.utc(2026, 5, 26, 11);

    await dataSource.saveMetadata(
      WidgetExportMetadata(
        status: WidgetExportStatus.failed,
        lastExportedAt: exportedAt,
        lastExportError: 'failed https://example.com/path?token=secret',
      ),
    );

    final metadata = await dataSource.loadMetadata();
    expect(metadata.status, WidgetExportStatus.failed);
    expect(metadata.lastExportedAt, exportedAt);
    expect(metadata.lastExportError, isNot(contains('token=secret')));
    expect(metadata.lastExportError, contains('https://example.com/path'));
  });

  test('stored summary JSON contains only summary fields', () async {
    final storage = MemoryJsonStorage();
    final dataSource = LocalWidgetSummaryDataSource(storage: storage);

    await dataSource.saveSummary(_summary());
    final raw = await storage.readString(
      LocalStorageKeys.widgetLatestSummaryJson,
    );
    final decoded = jsonDecode(raw!) as Map<String, Object?>;

    expect(decoded.keys, isNot(contains('rawDebugText')));
    expect(decoded.keys, isNot(contains('extractedPageText')));
    expect(decoded.keys, isNot(contains('matchedSignals')));
    expect(decoded.keys, isNot(contains('accountLabel')));
  });
}

WidgetSnapshotSummary _summary() {
  final now = DateTime.utc(2026, 5, 26, 10, 30);
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
