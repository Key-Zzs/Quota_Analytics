import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/app.dart';
import 'package:quota_analytics/core/storage/memory_json_storage.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';
import 'package:quota_analytics/features/widget_export/data/datasources/local_widget_summary_datasource.dart';
import 'package:quota_analytics/features/widget_export/data/mappers/quota_snapshot_to_widget_summary_mapper.dart';
import 'package:quota_analytics/features/widget_export/data/repositories/widget_summary_repository_impl.dart';
import 'package:quota_analytics/features/widget_export/domain/usecases/clear_widget_summary.dart';
import 'package:quota_analytics/features/widget_export/domain/usecases/export_widget_summary.dart';
import 'package:quota_analytics/features/widget_export/domain/usecases/get_widget_summary.dart';
import 'package:quota_analytics/features/widget_export/domain/usecases/notify_widget_update.dart';
import 'package:quota_analytics/features/widget_export/domain/repositories/widget_update_notifier.dart';
import 'package:quota_analytics/features/widget_export/presentation/controllers/widget_export_controller.dart';
import 'package:quota_analytics/features/widget_export/presentation/widgets/widget_export_status_card.dart';
import 'package:quota_analytics/features/widget_export/presentation/widgets/widget_summary_preview_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime.utc(2026, 5, 26, 10, 30);

  testWidgets('Debug page displays Widget Export section', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const QuotaAnalyticsApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Debug'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Widget Export'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Widget Export'), findsOneWidget);
    expect(find.text('Widget export enabled'), findsOneWidget);
    expect(find.text('Update Android widgets now'), findsOneWidget);
    expect(
      find.text('Export summary and update widgets now'),
      findsOneWidget,
    );
    expect(
      find.text('Clear widget summary and update widgets'),
      findsOneWidget,
    );
    expect(
      find.text('Widget refresh updates the widget view only.'),
      findsOneWidget,
    );
    expect(
      find.text('Widget does not refresh the web page in background.'),
      findsOneWidget,
    );
    expect(
      find.text('Widget reads display-safe summary only.'),
      findsOneWidget,
    );
    expect(
      find.text('Widget does not login, parse pages, or access WebView.'),
      findsOneWidget,
    );
  });

  testWidgets('WidgetExportStatusCard displays last exported at', (
    tester,
  ) async {
    final snapshot = QuotaSnapshotModel.mock(capturedAt: now, variant: 1);
    final controller = await _controllerWithExportedSummary(snapshot, now);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: WidgetExportStatusCard(
              controller: controller,
              latestSnapshot: snapshot,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Last widget exported at'), findsOneWidget);
    expect(find.textContaining('2026'), findsWidgets);
  });

  testWidgets(
    'WidgetSummaryPreviewCard displays Remaining ratio and Reset time',
    (tester) async {
      final snapshot = QuotaSnapshotModel.mock(capturedAt: now, variant: 1);
      final repository = _repository(now);
      final result = await repository.exportSummary(snapshot);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WidgetSummaryPreviewCard(summary: result.summary),
          ),
        ),
      );

      expect(find.textContaining('Remaining ratio'), findsWidgets);
      expect(find.textContaining('Reset time'), findsWidgets);
    },
  );

  testWidgets('Stage 10 widget export action buttons exist', (tester) async {
    final snapshot = QuotaSnapshotModel.mock(capturedAt: now, variant: 1);
    final controller = await _controllerWithExportedSummary(snapshot, now);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: WidgetExportStatusCard(
              controller: controller,
              latestSnapshot: snapshot,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Update Android widgets now'), findsOneWidget);
    expect(
      find.text('Export summary and update widgets now'),
      findsOneWidget,
    );
    expect(
      find.text('Clear widget summary and update widgets'),
      findsOneWidget,
    );
  });
}

Future<WidgetExportController> _controllerWithExportedSummary(
  QuotaSnapshotModel snapshot,
  DateTime now,
) async {
  final repository = _repository(now);
  final controller = WidgetExportController(
    exportWidgetSummary: ExportWidgetSummary(repository),
    getWidgetSummary: GetWidgetSummary(repository),
    clearWidgetSummary: ClearWidgetSummary(repository),
    notifyWidgetUpdate: const NotifyWidgetUpdate(NoopWidgetUpdateNotifier()),
  );
  await controller.exportNow(snapshot);
  return controller;
}

WidgetSummaryRepositoryImpl _repository(DateTime now) {
  return WidgetSummaryRepositoryImpl(
    dataSource: LocalWidgetSummaryDataSource(storage: MemoryJsonStorage()),
    mapper: const QuotaSnapshotToWidgetSummaryMapper(),
    clock: FixedClock(now),
  );
}
