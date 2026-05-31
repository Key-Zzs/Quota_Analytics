import '../entities/widget_shell_status.dart';
import '../entities/widget_update_result.dart';
import '../repositories/widget_update_notifier.dart';

class NotifyWidgetUpdate {
  const NotifyWidgetUpdate(this.notifier);

  final WidgetUpdateNotifier notifier;

  Future<WidgetUpdateResult> call() {
    return notifier.updateWidgets();
  }

  Future<WidgetShellStatus> getShellStatus() {
    return notifier.getShellStatus();
  }
}
