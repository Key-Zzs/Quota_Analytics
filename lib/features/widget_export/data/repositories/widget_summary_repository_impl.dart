import '../../../../core/security/sensitive_data_policy.dart';
import '../../../../core/time/clock.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../domain/entities/widget_export_metadata.dart';
import '../../domain/entities/widget_export_result.dart';
import '../../domain/entities/widget_export_status.dart';
import '../../domain/entities/widget_snapshot_summary.dart';
import '../../domain/entities/widget_update_result.dart';
import '../../domain/repositories/widget_summary_repository.dart';
import '../../domain/repositories/widget_update_notifier.dart';
import '../datasources/local_widget_summary_datasource.dart';
import '../mappers/quota_snapshot_to_widget_summary_mapper.dart';

class WidgetSummaryRepositoryImpl implements WidgetSummaryRepository {
  const WidgetSummaryRepositoryImpl({
    required this.dataSource,
    required this.mapper,
    required this.clock,
    this.widgetUpdateNotifier = const NoopWidgetUpdateNotifier(),
  });

  final LocalWidgetSummaryDataSource dataSource;
  final QuotaSnapshotToWidgetSummaryMapper mapper;
  final Clock clock;
  final WidgetUpdateNotifier widgetUpdateNotifier;

  @override
  Future<WidgetExportResult> exportSummary(QuotaSnapshot snapshot) async {
    final exportedAt = clock.now();
    try {
      final summary = mapper.map(snapshot, clock: clock);
      await dataSource.saveSummary(summary);
      final widgetUpdateResult = await _syncSummaryAndUpdate(summary);
      return WidgetExportResult(
        status: WidgetExportStatus.success,
        summary: summary,
        exportedAt: summary.exportedAt,
        safeError: null,
        widgetUpdateResult: widgetUpdateResult,
      );
    } on Object catch (error) {
      final safeError = SensitiveDataPolicy.sanitizeLogText(error.toString());
      await _trySaveFailureMetadata(exportedAt, safeError);
      return WidgetExportResult(
        status: WidgetExportStatus.failed,
        summary: null,
        exportedAt: exportedAt,
        safeError: safeError,
      );
    }
  }

  @override
  Future<WidgetSnapshotSummary?> getLatestSummary() {
    return dataSource.loadSummary();
  }

  @override
  Future<WidgetExportMetadata> getMetadata() {
    return dataSource.loadMetadata();
  }

  @override
  Future<WidgetExportResult> clearSummary() async {
    final clearedAt = clock.now();
    try {
      await dataSource.clearSummary(clearedAt: clearedAt);
      final widgetUpdateResult = await _clearNativeSummaryAndUpdate();
      return WidgetExportResult(
        status: WidgetExportStatus.cleared,
        summary: null,
        exportedAt: clearedAt,
        safeError: null,
        widgetUpdateResult: widgetUpdateResult,
      );
    } on Object catch (error) {
      final safeError = SensitiveDataPolicy.sanitizeLogText(error.toString());
      await _trySaveFailureMetadata(clearedAt, safeError);
      return WidgetExportResult(
        status: WidgetExportStatus.failed,
        summary: null,
        exportedAt: clearedAt,
        safeError: safeError,
      );
    }
  }

  Future<WidgetUpdateResult> _syncSummaryAndUpdate(
    WidgetSnapshotSummary summary,
  ) async {
    final syncResult = await _tryWidgetUpdateSideEffect(
      () => widgetUpdateNotifier.syncSummary(summary),
      operation: 'sync_summary',
    );
    if (syncResult.failed) {
      return syncResult;
    }
    return _tryWidgetUpdateSideEffect(
      widgetUpdateNotifier.updateWidgets,
      operation: 'update_widgets',
    );
  }

  Future<WidgetUpdateResult> _clearNativeSummaryAndUpdate() async {
    final clearResult = await _tryWidgetUpdateSideEffect(
      widgetUpdateNotifier.clearSummary,
      operation: 'clear_summary',
    );
    if (clearResult.failed) {
      return clearResult;
    }
    return _tryWidgetUpdateSideEffect(
      widgetUpdateNotifier.updateWidgets,
      operation: 'update_widgets',
    );
  }

  Future<WidgetUpdateResult> _tryWidgetUpdateSideEffect(
    Future<WidgetUpdateResult> Function() action, {
    required String operation,
  }) async {
    final attemptedAt = clock.now();
    try {
      return await action();
    } on Object catch (error) {
      return WidgetUpdateResult.failed(
        operation: operation,
        sentAt: attemptedAt,
        safeError: SensitiveDataPolicy.sanitizeLogText(error.toString()),
      );
    }
  }

  Future<void> _trySaveFailureMetadata(
    DateTime exportedAt,
    String safeError,
  ) async {
    try {
      await dataSource.saveMetadata(
        WidgetExportMetadata(
          status: WidgetExportStatus.failed,
          lastExportedAt: exportedAt,
          lastExportError: safeError,
        ),
      );
    } on Object {
      // Best effort only: widget export must not break quota refresh saves.
    }
  }
}
