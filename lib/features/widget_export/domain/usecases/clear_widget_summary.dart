import '../entities/widget_export_result.dart';
import '../repositories/widget_summary_repository.dart';

class ClearWidgetSummary {
  const ClearWidgetSummary(this.repository);

  final WidgetSummaryRepository repository;

  Future<WidgetExportResult> call() {
    return repository.clearSummary();
  }
}
