import '../entities/widget_shell_status.dart';
import '../entities/widget_update_result.dart';
import '../entities/widget_update_reason.dart';
import '../repositories/widget_update_notifier.dart';

class NotifyWidgetUpdate {
  const NotifyWidgetUpdate(this.notifier);

  final WidgetUpdateNotifier notifier;

  Future<WidgetUpdateResult> call({
    String reason = WidgetUpdateReason.debugUpdate,
  }) {
    return notifier.updateWidgets(reason: reason);
  }

  Future<WidgetShellStatus> getShellStatus() {
    return notifier.getShellStatus();
  }
}
