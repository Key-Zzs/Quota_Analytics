import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/storage/memory_json_storage.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';
import 'package:quota_analytics/features/widget_export/data/datasources/local_widget_summary_datasource.dart';
import 'package:quota_analytics/features/widget_export/data/mappers/quota_snapshot_to_widget_summary_mapper.dart';
import 'package:quota_analytics/features/widget_export/data/repositories/widget_summary_repository_impl.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_export_status.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_shell_status.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_snapshot_summary.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_update_result.dart';
import 'package:quota_analytics/features/widget_export/domain/repositories/widget_update_notifier.dart';
import 'package:quota_analytics/features/widget_export/domain/usecases/clear_widget_summary.dart';
import 'package:quota_analytics/features/widget_export/domain/usecases/export_widget_summary.dart';
import 'package:quota_analytics/features/widget_export/domain/usecases/get_widget_summary.dart';
import 'package:quota_analytics/features/widget_export/domain/usecases/notify_widget_update.dart';
import 'package:quota_analytics/features/widget_export/presentation/controllers/widget_export_controller.dart';

void main() {
  final now = DateTime.utc(2026, 5, 26, 10, 30);

  test('update status is recorded', () async {
    final notifier = _FakeWidgetUpdateNotifier(now: now);
    final controller = _controller(now: now, notifier: notifier);

    await controller.updateWidgetsNow();

    expect(controller.lastWidgetUpdateResult.success, isTrue);
    expect(controller.lastWidgetUpdateResult.operation, 'update_widgets');
    expect(controller.lastWidgetUpdateResult.sentAt, now);
    expect(controller.message, 'Android widget update signal sent.');
  });

  test('update error is recorded safely', () async {
    final notifier = _FakeWidgetUpdateNotifier(now: now, throwOnUpdate: true);
    final controller = _controller(now: now, notifier: notifier);

    await controller.updateWidgetsNow();

    expect(controller.lastWidgetUpdateResult.failed, isTrue);
    expect(controller.lastWidgetUpdateError, contains('token=<redacted>'));
    expect(controller.lastWidgetUpdateError, isNot(contains('token=secret')));
  });

  test('export records widget update failure without failing export', () async {
    final notifier = _FakeWidgetUpdateNotifier(now: now, failUpdate: true);
    final controller = _controller(now: now, notifier: notifier);
    final snapshot = QuotaSnapshotModel.mock(capturedAt: now, variant: 1);

    await controller.exportNow(snapshot);

    expect(controller.metadata.status, WidgetExportStatus.success);
    expect(controller.lastWidgetUpdateResult.failed, isTrue);
    expect(controller.summary?.id, snapshot.id);
  });
}

WidgetExportController _controller({
  required DateTime now,
  required WidgetUpdateNotifier notifier,
}) {
  final repository = WidgetSummaryRepositoryImpl(
    dataSource: LocalWidgetSummaryDataSource(storage: MemoryJsonStorage()),
    mapper: const QuotaSnapshotToWidgetSummaryMapper(),
    clock: FixedClock(now),
    widgetUpdateNotifier: notifier,
  );
  return WidgetExportController(
    exportWidgetSummary: ExportWidgetSummary(repository),
    getWidgetSummary: GetWidgetSummary(repository),
    clearWidgetSummary: ClearWidgetSummary(repository),
    notifyWidgetUpdate: NotifyWidgetUpdate(notifier),
  );
}

class _FakeWidgetUpdateNotifier implements WidgetUpdateNotifier {
  _FakeWidgetUpdateNotifier({
    required this.now,
    this.failUpdate = false,
    this.throwOnUpdate = false,
  });

  final DateTime now;
  final bool failUpdate;
  final bool throwOnUpdate;

  @override
  Future<WidgetUpdateResult> syncSummary(WidgetSnapshotSummary summary) async {
    return WidgetUpdateResult.success(operation: 'sync_summary', sentAt: now);
  }

  @override
  Future<WidgetUpdateResult> clearSummary() async {
    return WidgetUpdateResult.success(operation: 'clear_summary', sentAt: now);
  }

  @override
  Future<WidgetUpdateResult> updateWidgets() async {
    if (throwOnUpdate) {
      throw StateError('failed token=secret');
    }
    if (failUpdate) {
      return WidgetUpdateResult.failed(
        operation: 'update_widgets',
        sentAt: now,
        safeError: 'update failed',
      );
    }
    return WidgetUpdateResult.success(operation: 'update_widgets', sentAt: now);
  }

  @override
  Future<WidgetShellStatus> getShellStatus() async {
    return const WidgetShellStatus(
      available: true,
      installedWidgetCount: 1,
      hasInstalledWidgets: true,
      safeError: null,
    );
  }
}
