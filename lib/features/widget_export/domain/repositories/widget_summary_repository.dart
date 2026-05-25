import '../../../quota/domain/entities/quota_snapshot.dart';
import '../entities/widget_export_metadata.dart';
import '../entities/widget_export_result.dart';
import '../entities/widget_snapshot_summary.dart';

abstract class WidgetSummaryRepository {
  Future<WidgetExportResult> exportSummary(QuotaSnapshot snapshot);

  Future<WidgetSnapshotSummary?> getLatestSummary();

  Future<WidgetExportMetadata> getMetadata();

  Future<WidgetExportResult> clearSummary();
}
