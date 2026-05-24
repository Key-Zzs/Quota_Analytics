import '../../../quota/domain/entities/quota_snapshot.dart';
import '../entities/background_refresh_result.dart';
import '../entities/background_refresh_settings.dart';
import '../entities/refresh_failure_metadata.dart';

abstract class BackgroundRefreshRepository {
  Future<BackgroundRefreshSettings> getSettings();

  Future<BackgroundRefreshSettings> saveSettings(
    BackgroundRefreshSettings settings,
  );

  Future<void> clearSettings();

  Future<QuotaSnapshot?> getLatestSnapshotForBackground();

  Future<RefreshFailureMetadata> getLastRefreshFailureMetadata();

  Future<BackgroundRefreshResult?> getLastResult();

  Future<BackgroundRefreshResult> saveLastResult(
    BackgroundRefreshResult result,
  );

  Future<void> clearLastResult();

  Future<bool> hasBackgroundSafeDataSource();

  Future<void> schedule(BackgroundRefreshSettings settings);

  Future<void> cancel();
}
