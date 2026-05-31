import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/storage/json_storage.dart';
import 'package:quota_analytics/core/storage/memory_json_storage.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';
import 'package:quota_analytics/features/widget_export/data/datasources/local_widget_summary_datasource.dart';
import 'package:quota_analytics/features/widget_export/data/mappers/quota_snapshot_to_widget_summary_mapper.dart';
import 'package:quota_analytics/features/widget_export/data/repositories/widget_summary_repository_impl.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_export_status.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_shell_status.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_snapshot_summary.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_update_result.dart';
import 'package:quota_analytics/features/widget_export/domain/repositories/widget_update_notifier.dart';

void main() {
  final now = DateTime.utc(2026, 5, 26, 10, 30);

  test('export latest summary', () async {
    final repository = _repository(storage: MemoryJsonStorage(), now: now);
    final snapshot = QuotaSnapshotModel.mock(capturedAt: now, variant: 1);

    final result = await repository.exportSummary(snapshot);
    final loaded = await repository.getLatestSummary();

    expect(result.success, isTrue);
    expect(result.summary?.id, snapshot.id);
    expect(loaded?.id, snapshot.id);
    expect((await repository.getMetadata()).status, WidgetExportStatus.success);
  });

  test(
    'export success syncs native summary and signals widget update',
    () async {
      final notifier = _RecordingWidgetUpdateNotifier(now: now);
      final repository = _repository(
        storage: MemoryJsonStorage(),
        now: now,
        notifier: notifier,
      );
      final snapshot = QuotaSnapshotModel.mock(capturedAt: now, variant: 1);

      final result = await repository.exportSummary(snapshot);

      expect(result.success, isTrue);
      expect(notifier.syncSummaryCalls, 1);
      expect(notifier.updateWidgetsCalls, 1);
      expect(notifier.lastUpdateReason, 'snapshotSaved');
      expect(notifier.syncedSummary?.id, snapshot.id);
      expect(result.widgetUpdateResult?.success, isTrue);
    },
  );

  test('export failure returns safe error', () async {
    final notifier = _RecordingWidgetUpdateNotifier(now: now);
    final repository = _repository(
      storage: _ThrowingWriteStorage(),
      now: now,
      notifier: notifier,
    );
    final snapshot = QuotaSnapshotModel.mock(capturedAt: now, variant: 1);

    final result = await repository.exportSummary(snapshot);

    expect(result.status, WidgetExportStatus.failed);
    expect(result.safeError, contains('write failed'));
    expect(result.safeError, isNot(contains('token=secret')));
    expect(notifier.syncSummaryCalls, 0);
    expect(notifier.updateWidgetsCalls, 0);
  });

  test('widget update failure does not fail export', () async {
    final notifier = _RecordingWidgetUpdateNotifier(now: now, failUpdate: true);
    final repository = _repository(
      storage: MemoryJsonStorage(),
      now: now,
      notifier: notifier,
    );
    final snapshot = QuotaSnapshotModel.mock(capturedAt: now, variant: 1);

    final result = await repository.exportSummary(snapshot);

    expect(result.status, WidgetExportStatus.success);
    expect(result.widgetUpdateResult?.failed, isTrue);
    expect(result.widgetUpdateResult?.safeError, isNot(contains('secret')));
  });

  test('clear summary', () async {
    final notifier = _RecordingWidgetUpdateNotifier(now: now);
    final repository = _repository(
      storage: MemoryJsonStorage(),
      now: now,
      notifier: notifier,
    );
    await repository.exportSummary(
      QuotaSnapshotModel.mock(capturedAt: now, variant: 1),
    );
    notifier.resetCounts();

    final result = await repository.clearSummary();

    expect(result.status, WidgetExportStatus.cleared);
    expect(await repository.getLatestSummary(), isNull);
    expect((await repository.getMetadata()).status, WidgetExportStatus.cleared);
    expect(notifier.clearSummaryCalls, 1);
    expect(notifier.updateWidgetsCalls, 1);
    expect(notifier.lastUpdateReason, 'clearWidgetSummary');
  });

  test('missing summary returns no data state', () async {
    final repository = _repository(storage: MemoryJsonStorage(), now: now);

    expect(await repository.getLatestSummary(), isNull);
    expect(
      (await repository.getMetadata()).status,
      WidgetExportStatus.neverExported,
    );
  });
}

WidgetSummaryRepositoryImpl _repository({
  required JsonStorage storage,
  required DateTime now,
  WidgetUpdateNotifier notifier = const NoopWidgetUpdateNotifier(),
}) {
  return WidgetSummaryRepositoryImpl(
    dataSource: LocalWidgetSummaryDataSource(storage: storage),
    mapper: const QuotaSnapshotToWidgetSummaryMapper(),
    clock: FixedClock(now),
    widgetUpdateNotifier: notifier,
  );
}

class _ThrowingWriteStorage implements JsonStorage {
  @override
  String get backendName => 'throwing';

  @override
  Future<String?> readString(String key) async => null;

  @override
  Future<void> remove(String key) async {}

  @override
  Future<void> removeAll(Iterable<String> keys) async {}

  @override
  Future<void> writeString(String key, String value) async {
    throw StateError('write failed token=secret');
  }
}

class _RecordingWidgetUpdateNotifier implements WidgetUpdateNotifier {
  _RecordingWidgetUpdateNotifier({required this.now, this.failUpdate = false});

  final DateTime now;
  final bool failUpdate;

  int syncSummaryCalls = 0;
  int clearSummaryCalls = 0;
  int updateWidgetsCalls = 0;
  String? lastUpdateReason;
  WidgetSnapshotSummary? syncedSummary;

  void resetCounts() {
    syncSummaryCalls = 0;
    clearSummaryCalls = 0;
    updateWidgetsCalls = 0;
    lastUpdateReason = null;
  }

  @override
  Future<WidgetUpdateResult> syncSummary(WidgetSnapshotSummary summary) async {
    syncSummaryCalls += 1;
    syncedSummary = summary;
    return WidgetUpdateResult.success(operation: 'sync_summary', sentAt: now);
  }

  @override
  Future<WidgetUpdateResult> clearSummary() async {
    clearSummaryCalls += 1;
    return WidgetUpdateResult.success(operation: 'clear_summary', sentAt: now);
  }

  @override
  Future<WidgetUpdateResult> updateWidgets({
    String reason = 'unspecified',
  }) async {
    updateWidgetsCalls += 1;
    lastUpdateReason = reason;
    if (failUpdate) {
      return WidgetUpdateResult.failed(
        operation: 'update_widgets',
        reason: reason,
        sentAt: now,
        safeError: 'failed token=<redacted>',
      );
    }
    return WidgetUpdateResult.success(
      operation: 'update_widgets',
      reason: reason,
      sentAt: now,
    );
  }

  @override
  Future<WidgetShellStatus> getShellStatus() async {
    return const WidgetShellStatus(
      available: true,
      installedWidgetCount: 1,
      hasInstalledWidgets: true,
      safeError: null,
    );
  }
}
