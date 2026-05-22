import '../../domain/entities/quota_persistence_status.dart';
import '../../domain/entities/quota_snapshot.dart';
import '../../domain/repositories/quota_repository.dart';
import '../datasources/local_quota_datasource.dart';
import '../datasources/mock_quota_datasource.dart';

class PersistentQuotaRepository implements QuotaRepository {
  const PersistentQuotaRepository({
    required this.mockDataSource,
    required this.localDataSource,
  });

  final MockQuotaDataSource mockDataSource;
  final LocalQuotaDataSource localDataSource;

  @override
  Future<QuotaSnapshot> getLatestSnapshot() async {
    final cached = await localDataSource.loadLatestSnapshot();
    if (cached != null) {
      return cached;
    }
    return mockDataSource.getLatestSnapshot();
  }

  @override
  Future<QuotaSnapshot> refreshSnapshot() async {
    final snapshot = await mockDataSource.refreshSnapshot();
    await localDataSource.saveLatestSnapshot(snapshot);
    await localDataSource.appendHistory(snapshot);
    return snapshot;
  }

  @override
  Future<List<QuotaSnapshot>> getHistory() {
    return localDataSource.loadHistory();
  }

  @override
  Future<void> clearLocalQuotaData() async {
    await localDataSource.clearAll();
    mockDataSource.reset();
  }

  @override
  Future<QuotaPersistenceStatus> getPersistenceStatus() {
    return localDataSource.inspect();
  }
}
