import 'widget_export_status.dart';
import 'widget_snapshot_summary.dart';
import 'widget_update_result.dart';

class WidgetExportResult {
  const WidgetExportResult({
    required this.status,
    required this.summary,
    required this.exportedAt,
    required this.safeError,
    this.widgetUpdateResult,
  });

  final WidgetExportStatus status;
  final WidgetSnapshotSummary? summary;
  final DateTime? exportedAt;
  final String? safeError;
  final WidgetUpdateResult? widgetUpdateResult;

  bool get success => status == WidgetExportStatus.success;
}
