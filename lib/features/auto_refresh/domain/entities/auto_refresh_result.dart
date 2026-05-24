import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../../refresh/domain/entities/manual_refresh_result.dart';

class AutoRefreshResult {
  const AutoRefreshResult({
    required this.manualRefreshResult,
    required this.savedSnapshot,
  });

  final ManualRefreshResult manualRefreshResult;
  final QuotaSnapshot? savedSnapshot;

  bool get hasSuccessfulCandidate {
    return manualRefreshResult.hasSnapshotCandidate &&
        manualRefreshResult.errors.isEmpty;
  }

  bool get savedLocally => savedSnapshot != null || manualRefreshResult.isSaved;
}
