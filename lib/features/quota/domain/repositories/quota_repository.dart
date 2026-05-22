import '../entities/quota_snapshot.dart';

abstract class QuotaRepository {
  Future<QuotaSnapshot> getLatestSnapshot();
  Future<QuotaSnapshot> refreshSnapshot();
}
