import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/storage/local_storage_keys.dart';
import 'package:quota_analytics/core/storage/shared_preferences_storage.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/quota/data/datasources/local_quota_datasource.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saves and loads latest snapshot', () async {
    SharedPreferences.setMockInitialValues({});
    final dataSource = await _buildDataSource();
    final snapshot = _snapshot(0);

    await dataSource.saveLatestSnapshot(snapshot);
    final loaded = await dataSource.loadLatestSnapshot();

    expect(loaded, isNotNull);
    expect(loaded!.id, snapshot.id);
    expect(loaded.capturedAt, snapshot.capturedAt);
  });

  test('appends history and keeps newest 100 snapshots', () async {
    SharedPreferences.setMockInitialValues({});
    final dataSource = await _buildDataSource();

    for (var index = 0; index < 105; index += 1) {
      await dataSource.appendHistory(_snapshot(index));
    }

    final history = await dataSource.loadHistory();

    expect(history, hasLength(100));
    expect(history.first.capturedAt, _snapshot(104).capturedAt);
    expect(history.last.capturedAt, _snapshot(5).capturedAt);
  });

  test('clears latest snapshot and history', () async {
    SharedPreferences.setMockInitialValues({});
    final dataSource = await _buildDataSource();
    await dataSource.saveLatestSnapshot(_snapshot(1));
    await dataSource.appendHistory(_snapshot(1));

    await dataSource.clearAll();

    expect(await dataSource.loadLatestSnapshot(), isNull);
    expect(await dataSource.loadHistory(), isEmpty);
  });

  test('corrupted local data does not crash loading', () async {
    SharedPreferences.setMockInitialValues({
      LocalStorageKeys.quotaLatestSnapshot: '{bad json',
      LocalStorageKeys.quotaSnapshotHistory: '{"not":"a list"}',
    });
    final dataSource = await _buildDataSource();

    final latest = await dataSource.loadLatestSnapshot();
    final history = await dataSource.loadHistory();
    final status = await dataSource.inspect();

    expect(latest, isNull);
    expect(history, isEmpty);
    expect(status.lastError, isNotNull);
  });
}

Future<LocalQuotaDataSource> _buildDataSource() async {
  return LocalQuotaDataSource(
    storage: await SharedPreferencesStorage.create(),
    clock: FixedClock(DateTime.utc(2026, 1, 1)),
  );
}

QuotaSnapshotModel _snapshot(int variant) {
  return QuotaSnapshotModel.mock(
    capturedAt: DateTime.utc(2026, 1, 1, 12).add(Duration(minutes: variant)),
    variant: variant,
  );
}
