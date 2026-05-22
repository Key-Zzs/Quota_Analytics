import '../entities/quota_snapshot.dart';
import '../repositories/quota_repository.dart';

class GetQuotaHistory {
  const GetQuotaHistory(this.repository);

  final QuotaRepository repository;

  Future<List<QuotaSnapshot>> call() => repository.getHistory();
}
