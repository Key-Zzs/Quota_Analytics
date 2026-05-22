import '../entities/quota_persistence_status.dart';
import '../entities/quota_snapshot.dart';

abstract class QuotaRepository {
  Future<QuotaSnapshot> getLatestSnapshot();
  Future<QuotaSnapshot> refreshSnapshot();
  Future<List<QuotaSnapshot>> getHistory();
  Future<void> clearLocalQuotaData();
  Future<QuotaPersistenceStatus> getPersistenceStatus();
}
