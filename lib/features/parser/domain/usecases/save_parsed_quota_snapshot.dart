import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../../quota/domain/repositories/quota_repository.dart';

class SaveParsedQuotaSnapshot {
  const SaveParsedQuotaSnapshot(this.repository);

  final QuotaRepository repository;

  Future<QuotaSnapshot> call(QuotaSnapshot snapshot) {
    return repository.saveSnapshot(snapshot);
  }
}
