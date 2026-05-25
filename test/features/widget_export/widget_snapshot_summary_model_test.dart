import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/widget_export/data/models/widget_snapshot_summary_model.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_snapshot_summary.dart';

void main() {
  test('JSON round trip keeps schema version and ISO dates', () {
    final exportedAt = DateTime.utc(2026, 5, 26, 10, 30);
    final resetAt = DateTime.utc(2026, 5, 26, 12, 45);
    final summary = WidgetSnapshotSummaryModel(
      schemaVersion: WidgetSnapshotSummary.currentSchemaVersion,
      id: 'snapshot-1',
      fiveHourRemainingRatio: 0.42,
      fiveHourResetText: 'Reset time available',
      fiveHourResetAt: resetAt,
      weeklyRemainingRatio: null,
      weeklyResetText: null,
      weeklyResetAt: null,
      creditsRemaining: 12.5,
      lastUpdatedAt: exportedAt,
      source: 'webViewManualExtraction',
      parserConfidence: 'high',
      isStale: false,
      staleReason: 'fresh',
      displayTitle: 'Quota Analytics',
      displaySubtitle: 'Updated 10:30',
      statusLabel: 'OK',
      errorLabel: null,
      exportedAt: exportedAt,
    );

    final json = summary.toJson();
    final copy = WidgetSnapshotSummaryModel.fromJson(json);

    expect(json['schemaVersion'], '1');
    expect(json['fiveHourResetAt'], resetAt.toIso8601String());
    expect(json['exportedAt'], exportedAt.toIso8601String());
    expect(json['source'], 'webViewManualExtraction');
    expect(json['parserConfidence'], 'high');
    expect(copy.schemaVersion, '1');
    expect(copy.fiveHourRemainingRatio, 0.42);
    expect(copy.weeklyRemainingRatio, isNull);
    expect(copy.exportedAt, exportedAt);
  });

  test('null fields are handled and enum-like fields are strings', () {
    final exportedAt = DateTime.utc(2026, 5, 26, 10, 30);
    final summary = WidgetSnapshotSummaryModel.fromJson({
      'schemaVersion': '1',
      'id': 'snapshot-2',
      'source': 'mock',
      'parserConfidence': 'notApplicable',
      'isStale': false,
      'staleReason': 'fresh',
      'displayTitle': 'Quota Analytics',
      'displaySubtitle': 'No quota data',
      'exportedAt': exportedAt.toIso8601String(),
    });

    final json = summary.toJson();

    expect(summary.fiveHourRemainingRatio, isNull);
    expect(summary.weeklyRemainingRatio, isNull);
    expect(json['source'], isA<String>());
    expect(json['parserConfidence'], isA<String>());
    expect(json['source'], isNot(isA<int>()));
    expect(json['parserConfidence'], isNot(isA<int>()));
  });
}
