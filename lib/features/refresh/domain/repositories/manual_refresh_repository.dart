import '../entities/manual_refresh_result.dart';

abstract class ManualRefreshRepository {
  Future<ManualRefreshResult?> getLastResult();

  Future<ManualRefreshResult> saveLastResult(ManualRefreshResult result);

  Future<void> clearLastResult();
}
