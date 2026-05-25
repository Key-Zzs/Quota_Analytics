import 'widget_export_status.dart';
import 'widget_snapshot_summary.dart';

class WidgetExportResult {
  const WidgetExportResult({
    required this.status,
    required this.summary,
    required this.exportedAt,
    required this.safeError,
  });

  final WidgetExportStatus status;
  final WidgetSnapshotSummary? summary;
  final DateTime? exportedAt;
  final String? safeError;

  bool get success => status == WidgetExportStatus.success;
}
