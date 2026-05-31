import '../entities/widget_shell_status.dart';
import '../entities/widget_snapshot_summary.dart';
import '../entities/widget_update_result.dart';

abstract class WidgetUpdateNotifier {
  Future<WidgetUpdateResult> syncSummary(WidgetSnapshotSummary summary);

  Future<WidgetUpdateResult> clearSummary();

  Future<WidgetUpdateResult> updateWidgets();

  Future<WidgetShellStatus> getShellStatus();
}

class NoopWidgetUpdateNotifier implements WidgetUpdateNotifier {
  const NoopWidgetUpdateNotifier();

  @override
  Future<WidgetUpdateResult> syncSummary(WidgetSnapshotSummary summary) async {
    return WidgetUpdateResult.skipped(
      operation: 'sync_summary',
      safeError: 'Android widget channel unavailable',
    );
  }

  @override
  Future<WidgetUpdateResult> clearSummary() async {
    return WidgetUpdateResult.skipped(
      operation: 'clear_summary',
      safeError: 'Android widget channel unavailable',
    );
  }

  @override
  Future<WidgetUpdateResult> updateWidgets() async {
    return WidgetUpdateResult.skipped(
      operation: 'update_widgets',
      safeError: 'Android widget channel unavailable',
    );
  }

  @override
  Future<WidgetShellStatus> getShellStatus() async {
    return WidgetShellStatus.unknown(
      safeError: 'Android widget channel unavailable',
    );
  }
}
