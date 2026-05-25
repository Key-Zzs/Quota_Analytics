import '../../../quota/domain/entities/quota_snapshot.dart';
import '../entities/widget_export_result.dart';
import '../repositories/widget_summary_repository.dart';

class ExportWidgetSummary {
  const ExportWidgetSummary(this.repository);

  final WidgetSummaryRepository repository;

  Future<WidgetExportResult> call(QuotaSnapshot snapshot) {
    return repository.exportSummary(snapshot);
  }
}
