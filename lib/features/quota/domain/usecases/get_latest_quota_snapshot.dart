import '../entities/quota_snapshot.dart';
import '../repositories/quota_repository.dart';

class GetLatestQuotaSnapshot {
  const GetLatestQuotaSnapshot(this.repository);

  final QuotaRepository repository;

  Future<QuotaSnapshot> call() => repository.getLatestSnapshot();
}
