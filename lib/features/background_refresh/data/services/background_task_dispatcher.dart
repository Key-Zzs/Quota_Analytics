import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../../../../core/storage/shared_preferences_storage.dart';
import '../../../../core/time/clock.dart';
import '../../../notifications/data/datasources/local_notification_datasource.dart';
import '../../../notifications/data/datasources/notification_metadata_datasource.dart';
import '../../../notifications/data/repositories/local_notification_repository.dart';
import '../../../notifications/domain/usecases/evaluate_notification_rules.dart';
import '../../../notifications/domain/usecases/send_quota_notification.dart';
import '../../../widget_export/data/datasources/local_widget_summary_datasource.dart';
import '../../../widget_export/data/mappers/quota_snapshot_to_widget_summary_mapper.dart';
import '../../../widget_export/data/repositories/widget_summary_repository_impl.dart';
import '../../../widget_export/domain/entities/widget_update_reason.dart';
import '../../domain/usecases/evaluate_background_refresh_eligibility.dart';
import '../../domain/usecases/run_background_refresh_check.dart';
import '../datasources/local_background_refresh_datasource.dart';
import '../datasources/workmanager_background_task_datasource.dart';
import '../repositories/background_refresh_repository_impl.dart';

@pragma('vm:entry-point')
void quotaBackgroundTaskDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    if (taskName != WorkmanagerBackgroundTaskDataSource.taskName) {
      return true;
    }

    final clock = const SystemClock();
    final storage = await SharedPreferencesStorage.create();
    final backgroundRepository = BackgroundRefreshRepositoryImpl(
      localDataSource: LocalBackgroundRefreshDataSource(
        storage: storage,
        clock: clock,
      ),
      workmanagerDataSource: WorkmanagerBackgroundTaskDataSource(),
      clock: clock,
    );
    final notificationRepository = LocalNotificationRepository(
      notificationDataSource: LocalNotificationDataSource(),
      metadataDataSource: NotificationMetadataDataSource(storage: storage),
      clock: clock,
    );
    final widgetSummaryRepository = WidgetSummaryRepositoryImpl(
      dataSource: LocalWidgetSummaryDataSource(storage: storage),
      mapper: const QuotaSnapshotToWidgetSummaryMapper(),
      clock: clock,
    );
    final runCheck = RunBackgroundRefreshCheck(
      backgroundRepository: backgroundRepository,
      notificationRepository: notificationRepository,
      evaluateEligibility: const EvaluateBackgroundRefreshEligibility(),
      evaluateNotificationRules: const EvaluateNotificationRules(),
      sendQuotaNotification: SendQuotaNotification(notificationRepository),
      onLatestSnapshotCheckedForWidget: (snapshot) {
        return widgetSummaryRepository.exportSummary(
          snapshot,
          updateReason: WidgetUpdateReason.backgroundNotifyOnlyCheck,
        );
      },
    );
    final result = await runCheck(now: clock.now());
    return result.errors.isEmpty;
  });
}

class BackgroundTaskDispatcher {
  const BackgroundTaskDispatcher._();

  static Future<void> initialize() async {
    if (!Platform.isAndroid) {
      return;
    }
    await Workmanager().initialize(quotaBackgroundTaskDispatcher);
  }
}
