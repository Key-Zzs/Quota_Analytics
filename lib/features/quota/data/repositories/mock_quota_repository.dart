import '../../domain/entities/quota_persistence_status.dart';
import '../../domain/entities/quota_snapshot.dart';
import '../../domain/repositories/quota_repository.dart';
import '../datasources/mock_quota_datasource.dart';

class MockQuotaRepository implements QuotaRepository {
  MockQuotaRepository(this.dataSource);

  final MockQuotaDataSource dataSource;
  QuotaSnapshot? _savedSnapshot;

  @override
  Future<QuotaSnapshot> getLatestSnapshot() {
    final savedSnapshot = _savedSnapshot;
    if (savedSnapshot != null) {
      return Future.value(savedSnapshot);
    }
    return dataSource.getLatestSnapshot();
  }

  @override
  Future<QuotaSnapshot> refreshSnapshot() {
    return dataSource.refreshSnapshot();
  }

  @override
  Future<QuotaSnapshot> saveSnapshot(QuotaSnapshot snapshot) async {
    _savedSnapshot = snapshot;
    return snapshot;
  }

  @override
  Future<List<QuotaSnapshot>> getHistory() async {
    final savedSnapshot = _savedSnapshot;
    return savedSnapshot == null ? const [] : [savedSnapshot];
  }

  @override
  Future<void> clearLocalQuotaData() async {
    _savedSnapshot = null;
    dataSource.reset();
  }

  @override
  Future<QuotaPersistenceStatus> getPersistenceStatus() async {
    return QuotaPersistenceStatus.mockOnly();
  }
}
