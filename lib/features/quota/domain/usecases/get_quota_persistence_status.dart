import '../entities/quota_persistence_status.dart';
import '../repositories/quota_repository.dart';

class GetQuotaPersistenceStatus {
  const GetQuotaPersistenceStatus(this.repository);

  final QuotaRepository repository;

  Future<QuotaPersistenceStatus> call() => repository.getPersistenceStatus();
}
