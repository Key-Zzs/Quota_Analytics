import '../../../../core/time/clock.dart';
import '../models/quota_snapshot_model.dart';

class MockQuotaDataSource {
  MockQuotaDataSource({
    required this.clock,
    this.refreshDelay = const Duration(milliseconds: 500),
  });

  final Clock clock;
  final Duration refreshDelay;

  QuotaSnapshotModel? _latestSnapshot;
  int _refreshCount = 0;

  Future<QuotaSnapshotModel> getLatestSnapshot() async {
    return _latestSnapshot ??= QuotaSnapshotModel.mock(
      capturedAt: clock.now(),
      variant: _refreshCount,
    );
  }

  Future<QuotaSnapshotModel> refreshSnapshot() async {
    if (refreshDelay > Duration.zero) {
      await Future<void>.delayed(refreshDelay);
    }

    _refreshCount += 1;
    final snapshot = QuotaSnapshotModel.mock(
      capturedAt: clock.now(),
      variant: _refreshCount,
    );
    _latestSnapshot = snapshot;
    return snapshot;
  }

  void reset() {
    _latestSnapshot = null;
    _refreshCount = 0;
  }
}
