import 'package:workmanager/workmanager.dart';

import '../../../../core/platform/android_platform_capabilities.dart';
import '../../domain/entities/background_refresh_settings.dart';

class WorkmanagerBackgroundTaskDataSource {
  WorkmanagerBackgroundTaskDataSource({
    Workmanager? workmanager,
    this.capabilities = const AndroidPlatformCapabilities(),
  }) : _workmanager = workmanager ?? Workmanager();

  static const uniqueTaskName = 'quota_background_refresh_periodic';
  static const taskName = 'quota_background_refresh_check';
  static const tag = 'quota_background_refresh';

  final Workmanager _workmanager;
  final AndroidPlatformCapabilities capabilities;

  Future<void> schedule(BackgroundRefreshSettings settings) async {
    if (!capabilities.supportsWorkManager || !settings.shouldSchedule) {
      return;
    }
    final frequency = settings.checkInterval.duration;
    if (frequency == null) {
      return;
    }
    await _workmanager.registerPeriodicTask(
      uniqueTaskName,
      taskName,
      frequency: frequency,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      tag: tag,
      inputData: const {'purpose': 'local_snapshot_notification_check'},
    );
  }

  Future<void> cancel() async {
    if (!capabilities.supportsWorkManager) {
      return;
    }
    await _workmanager.cancelByUniqueName(uniqueTaskName);
  }
}
