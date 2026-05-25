import '../../../../core/security/sensitive_data_policy.dart';
import '../../../../core/time/clock.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../domain/entities/widget_export_metadata.dart';
import '../../domain/entities/widget_export_result.dart';
import '../../domain/entities/widget_export_status.dart';
import '../../domain/entities/widget_snapshot_summary.dart';
import '../../domain/repositories/widget_summary_repository.dart';
import '../datasources/local_widget_summary_datasource.dart';
import '../mappers/quota_snapshot_to_widget_summary_mapper.dart';

class WidgetSummaryRepositoryImpl implements WidgetSummaryRepository {
  const WidgetSummaryRepositoryImpl({
    required this.dataSource,
    required this.mapper,
    required this.clock,
  });

  final LocalWidgetSummaryDataSource dataSource;
  final QuotaSnapshotToWidgetSummaryMapper mapper;
  final Clock clock;

  @override
  Future<WidgetExportResult> exportSummary(QuotaSnapshot snapshot) async {
    final exportedAt = clock.now();
    try {
      final summary = mapper.map(snapshot, clock: clock);
      await dataSource.saveSummary(summary);
      return WidgetExportResult(
        status: WidgetExportStatus.success,
        summary: summary,
        exportedAt: summary.exportedAt,
        safeError: null,
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
      return WidgetExportResult(
        status: WidgetExportStatus.cleared,
        summary: null,
        exportedAt: clearedAt,
        safeError: null,
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
