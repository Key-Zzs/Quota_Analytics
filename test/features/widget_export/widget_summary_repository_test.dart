import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/storage/json_storage.dart';
import 'package:quota_analytics/core/storage/memory_json_storage.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';
import 'package:quota_analytics/features/widget_export/data/datasources/local_widget_summary_datasource.dart';
import 'package:quota_analytics/features/widget_export/data/mappers/quota_snapshot_to_widget_summary_mapper.dart';
import 'package:quota_analytics/features/widget_export/data/repositories/widget_summary_repository_impl.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_export_status.dart';

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

  test('export failure returns safe error', () async {
    final repository = _repository(storage: _ThrowingWriteStorage(), now: now);
    final snapshot = QuotaSnapshotModel.mock(capturedAt: now, variant: 1);

    final result = await repository.exportSummary(snapshot);

    expect(result.status, WidgetExportStatus.failed);
    expect(result.safeError, contains('write failed'));
    expect(result.safeError, isNot(contains('token=secret')));
  });

  test('clear summary', () async {
    final repository = _repository(storage: MemoryJsonStorage(), now: now);
    await repository.exportSummary(
      QuotaSnapshotModel.mock(capturedAt: now, variant: 1),
    );

    final result = await repository.clearSummary();

    expect(result.status, WidgetExportStatus.cleared);
    expect(await repository.getLatestSummary(), isNull);
    expect((await repository.getMetadata()).status, WidgetExportStatus.cleared);
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
}) {
  return WidgetSummaryRepositoryImpl(
    dataSource: LocalWidgetSummaryDataSource(storage: storage),
    mapper: const QuotaSnapshotToWidgetSummaryMapper(),
    clock: FixedClock(now),
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
