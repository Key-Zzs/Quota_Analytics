import '../entities/widget_shell_status.dart';
import '../entities/widget_snapshot_summary.dart';
import '../entities/widget_update_result.dart';
import '../entities/widget_update_reason.dart';

abstract class WidgetUpdateNotifier {
  Future<WidgetUpdateResult> syncSummary(WidgetSnapshotSummary summary);

  Future<WidgetUpdateResult> clearSummary();

  Future<WidgetUpdateResult> updateWidgets({
    String reason = WidgetUpdateReason.unspecified,
  });

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
  Future<WidgetUpdateResult> updateWidgets({
    String reason = WidgetUpdateReason.unspecified,
  }) async {
    return WidgetUpdateResult.skipped(
      operation: 'update_widgets',
      reason: reason,
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
