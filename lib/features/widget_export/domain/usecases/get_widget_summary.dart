import '../entities/widget_export_metadata.dart';
import '../entities/widget_snapshot_summary.dart';
import '../repositories/widget_summary_repository.dart';

class GetWidgetSummary {
  const GetWidgetSummary(this.repository);

  final WidgetSummaryRepository repository;

  Future<WidgetSnapshotSummary?> call() {
    return repository.getLatestSummary();
  }

  Future<WidgetExportMetadata> metadata() {
    return repository.getMetadata();
  }
}
