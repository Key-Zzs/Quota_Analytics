import '../repositories/quota_repository.dart';

class ClearQuotaHistory {
  const ClearQuotaHistory(this.repository);

  final QuotaRepository repository;

  Future<void> call() => repository.clearLocalQuotaData();
}
