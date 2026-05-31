import '../entities/widget_export_result.dart';
import '../entities/widget_update_reason.dart';
import '../repositories/widget_summary_repository.dart';

class ClearWidgetSummary {
  const ClearWidgetSummary(this.repository);

  final WidgetSummaryRepository repository;

  Future<WidgetExportResult> call({
    String updateReason = WidgetUpdateReason.clearWidgetSummary,
  }) {
    return repository.clearSummary(updateReason: updateReason);
  }
}
