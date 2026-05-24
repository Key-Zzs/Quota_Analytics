import '../../../../core/time/clock.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../domain/entities/background_refresh_result.dart';
import '../../domain/entities/background_refresh_settings.dart';
import '../../domain/entities/refresh_failure_metadata.dart';
import '../../domain/repositories/background_safe_quota_data_source.dart';
import '../../domain/repositories/background_refresh_repository.dart';
import '../datasources/local_background_refresh_datasource.dart';
import '../datasources/noop_background_safe_datasource.dart';
import '../datasources/workmanager_background_task_datasource.dart';

class BackgroundRefreshRepositoryImpl implements BackgroundRefreshRepository {
  const BackgroundRefreshRepositoryImpl({
    required this.localDataSource,
    required this.workmanagerDataSource,
    required this.clock,
    this.backgroundSafeDataSource = const NoopBackgroundSafeDataSource(),
  });

  final LocalBackgroundRefreshDataSource localDataSource;
  final WorkmanagerBackgroundTaskDataSource workmanagerDataSource;
  final Clock clock;
  final BackgroundSafeQuotaDataSource backgroundSafeDataSource;

  @override
  Future<BackgroundRefreshSettings> getSettings() async {
    return await localDataSource.loadSettings() ??
        BackgroundRefreshSettings.defaults(clock.now());
  }

  @override
  Future<BackgroundRefreshSettings> saveSettings(
    BackgroundRefreshSettings settings,
  ) {
    return localDataSource.saveSettings(
      settings.copyWith(updatedAt: clock.now()),
    );
  }

  @override
  Future<void> clearSettings() {
    return localDataSource.clearSettings();
  }

  @override
  Future<QuotaSnapshot?> getLatestSnapshotForBackground() {
    return localDataSource.loadLatestSnapshotForBackground();
  }

  @override
  Future<RefreshFailureMetadata> getLastRefreshFailureMetadata() {
    return localDataSource.loadLastRefreshFailureMetadata();
  }

  @override
  Future<BackgroundRefreshResult?> getLastResult() {
    return localDataSource.loadLastResult();
  }

  @override
  Future<BackgroundRefreshResult> saveLastResult(
    BackgroundRefreshResult result,
  ) {
    return localDataSource.saveLastResult(result);
  }

  @override
  Future<void> clearLastResult() {
    return localDataSource.clearLastResult();
  }

  @override
  Future<bool> hasBackgroundSafeDataSource() async {
    return backgroundSafeDataSource.isAvailable;
  }

  @override
  Future<void> schedule(BackgroundRefreshSettings settings) {
    return workmanagerDataSource.schedule(settings);
  }

  @override
  Future<void> cancel() {
    return workmanagerDataSource.cancel();
  }
}
