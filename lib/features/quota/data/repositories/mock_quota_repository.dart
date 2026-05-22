import '../../domain/entities/quota_snapshot.dart';
import '../../domain/repositories/quota_repository.dart';
import '../datasources/mock_quota_datasource.dart';

class MockQuotaRepository implements QuotaRepository {
  const MockQuotaRepository(this.dataSource);

  final MockQuotaDataSource dataSource;

  @override
  Future<QuotaSnapshot> getLatestSnapshot() {
    return dataSource.getLatestSnapshot();
  }

  @override
  Future<QuotaSnapshot> refreshSnapshot() {
    return dataSource.refreshSnapshot();
  }
}
