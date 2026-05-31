import '../../../quota/domain/entities/quota_snapshot.dart';
import '../entities/widget_export_result.dart';
import '../entities/widget_update_reason.dart';
import '../repositories/widget_summary_repository.dart';

class ExportWidgetSummary {
  const ExportWidgetSummary(this.repository);

  final WidgetSummaryRepository repository;

  Future<WidgetExportResult> call(
    QuotaSnapshot snapshot, {
    String updateReason = WidgetUpdateReason.debugExport,
  }) {
    return repository.exportSummary(snapshot, updateReason: updateReason);
  }
}
