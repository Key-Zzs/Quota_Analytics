import '../../../quota/domain/entities/quota_persistence_status.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../../quota/domain/entities/quota_source.dart';
import '../../../quota/domain/repositories/quota_repository.dart';
import '../../domain/repositories/widget_summary_repository.dart';
import '../../domain/entities/widget_update_reason.dart';

class WidgetExportingQuotaRepository implements QuotaRepository {
  const WidgetExportingQuotaRepository({
    required this.delegate,
    required this.widgetRepository,
  });

  final QuotaRepository delegate;
  final WidgetSummaryRepository widgetRepository;

  @override
  Future<void> clearLocalQuotaData() async {
    await delegate.clearLocalQuotaData();
    await _clearWidgetSummarySafely(WidgetUpdateReason.clearData);
  }

  @override
  Future<List<QuotaSnapshot>> getHistory() {
    return delegate.getHistory();
  }

  @override
  Future<QuotaSnapshot> getLatestSnapshot() async {
    final snapshot = await delegate.getLatestSnapshot();
    final status = await delegate.getPersistenceStatus();
    if (status.loadedFromLocalCache || snapshot.source != QuotaSource.mock) {
      await _exportWidgetSummarySafely(
        snapshot,
        WidgetUpdateReason.appStartup,
      );
    }
    return snapshot;
  }

  @override
  Future<QuotaPersistenceStatus> getPersistenceStatus() {
    return delegate.getPersistenceStatus();
  }

  @override
  Future<QuotaSnapshot> refreshSnapshot() async {
    final snapshot = await delegate.refreshSnapshot();
    await _exportWidgetSummarySafely(snapshot, WidgetUpdateReason.manualRefresh);
    return snapshot;
  }

  @override
  Future<QuotaSnapshot> saveSnapshot(QuotaSnapshot snapshot) async {
    final saved = await delegate.saveSnapshot(snapshot);
    await _exportWidgetSummarySafely(saved, WidgetUpdateReason.snapshotSaved);
    return saved;
  }

  Future<void> _exportWidgetSummarySafely(
    QuotaSnapshot snapshot,
    String updateReason,
  ) async {
    try {
      await widgetRepository.exportSummary(
        snapshot,
        updateReason: updateReason,
      );
    } on Object {
      // Widget export is a debug-visible side effect, never a save blocker.
    }
  }

  Future<void> _clearWidgetSummarySafely(String updateReason) async {
    try {
      await widgetRepository.clearSummary(updateReason: updateReason);
    } on Object {
      // Clearing quota data should not be blocked by widget export metadata.
    }
  }
}
