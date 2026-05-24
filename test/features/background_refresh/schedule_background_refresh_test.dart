import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_check_interval.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_refresh_mode.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_refresh_result.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_refresh_settings.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/refresh_failure_metadata.dart';
import 'package:quota_analytics/features/background_refresh/domain/repositories/background_refresh_repository.dart';
import 'package:quota_analytics/features/background_refresh/domain/usecases/cancel_background_refresh.dart';
import 'package:quota_analytics/features/background_refresh/domain/usecases/schedule_background_refresh.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_snapshot.dart';

void main() {
  test('schedule delegates to repository adapter', () async {
    final repository = _FakeBackgroundRepository();
    final settings = BackgroundRefreshSettings.defaults(DateTime(2026))
        .copyWith(
          mode: BackgroundRefreshMode.notifyOnly,
          checkInterval: BackgroundCheckInterval.oneHour,
        );

    await ScheduleBackgroundRefresh(repository)(settings);

    expect(repository.scheduledSettings, settings);
    expect(repository.scheduleCalls, 1);
  });

  test('cancel delegates to repository adapter', () async {
    final repository = _FakeBackgroundRepository();

    await CancelBackgroundRefresh(repository)();

    expect(repository.cancelCalls, 1);
  });
}

class _FakeBackgroundRepository implements BackgroundRefreshRepository {
  int scheduleCalls = 0;
  int cancelCalls = 0;
  BackgroundRefreshSettings? scheduledSettings;

  @override
  Future<void> cancel() async {
    cancelCalls += 1;
  }

  @override
  Future<void> clearLastResult() async {}

  @override
  Future<void> clearSettings() async {}

  @override
  Future<bool> hasBackgroundSafeDataSource() async => false;

  @override
  Future<BackgroundRefreshResult?> getLastResult() async => null;

  @override
  Future<RefreshFailureMetadata> getLastRefreshFailureMetadata() async =>
      RefreshFailureMetadata.none;

  @override
  Future<QuotaSnapshot?> getLatestSnapshotForBackground() async => null;

  @override
  Future<BackgroundRefreshSettings> getSettings() async =>
      BackgroundRefreshSettings.defaults(DateTime(2026));

  @override
  Future<BackgroundRefreshResult> saveLastResult(
    BackgroundRefreshResult result,
  ) async => result;

  @override
  Future<BackgroundRefreshSettings> saveSettings(
    BackgroundRefreshSettings settings,
  ) async => settings;

  @override
  Future<void> schedule(BackgroundRefreshSettings settings) async {
    scheduleCalls += 1;
    scheduledSettings = settings;
  }
}
