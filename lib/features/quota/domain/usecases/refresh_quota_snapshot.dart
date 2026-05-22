import '../entities/quota_snapshot.dart';
import '../repositories/quota_repository.dart';

class RefreshQuotaSnapshot {
  const RefreshQuotaSnapshot(this.repository);

  final QuotaRepository repository;

  Future<QuotaSnapshot> call() => repository.refreshSnapshot();
}
