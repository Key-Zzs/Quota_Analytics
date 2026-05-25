import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';
import 'package:quota_analytics/features/widget_export/data/datasources/local_widget_summary_datasource.dart';
import 'package:quota_analytics/features/widget_export/data/mappers/quota_snapshot_to_widget_summary_mapper.dart';
import 'package:quota_analytics/features/widget_export/data/repositories/widget_summary_repository_impl.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_export_status.dart';
import 'package:quota_analytics/features/widget_export/domain/usecases/clear_widget_summary.dart';
import 'package:quota_analytics/features/widget_export/domain/usecases/export_widget_summary.dart';
import 'package:quota_analytics/features/widget_export/domain/usecases/get_widget_summary.dart';

import '../../helpers/recording_json_storage.dart';

void main() {
  test('usecases export get and clear widget summary', () async {
    final now = DateTime.utc(2026, 5, 26, 10, 30);
    final repository = WidgetSummaryRepositoryImpl(
      dataSource: LocalWidgetSummaryDataSource(storage: RecordingJsonStorage()),
      mapper: const QuotaSnapshotToWidgetSummaryMapper(),
      clock: FixedClock(now),
    );
    final export = ExportWidgetSummary(repository);
    final get = GetWidgetSummary(repository);
    final clear = ClearWidgetSummary(repository);
    final snapshot = QuotaSnapshotModel.mock(capturedAt: now, variant: 1);

    final exportResult = await export(snapshot);
    final loaded = await get();
    final clearResult = await clear();

    expect(exportResult.status, WidgetExportStatus.success);
    expect(loaded?.id, snapshot.id);
    expect(clearResult.status, WidgetExportStatus.cleared);
    expect(await get(), isNull);
  });
}
