import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';
import 'package:quota_analytics/features/quota/data/models/quota_window_model.dart';
import 'package:quota_analytics/features/quota/domain/entities/parser_confidence.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_source.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_window.dart';

void main() {
  test('QuotaWindow JSON round-trip keeps key fields', () {
    final window = QuotaWindowModel.fromEntity(
      QuotaWindow.fromUsage(
        label: '5-hour window',
        used: 64,
        limit: 100,
        resetAt: DateTime.utc(2026, 1, 1, 14),
      ),
    );

    final decoded = QuotaWindowModel.fromJson(
      window.toJson(),
      fallbackLabel: 'fallback',
    );

    expect(decoded.label, window.label);
    expect(decoded.used, window.used);
    expect(decoded.limit, window.limit);
    expect(decoded.remaining, window.remaining);
    expect(decoded.remainingRatio, window.remainingRatio);
    expect(decoded.resetAt, window.resetAt);
    expect(decoded.status, window.status);
  });

  test('QuotaSnapshot JSON round-trip keeps key fields', () {
    final snapshot = QuotaSnapshotModel.mock(
      capturedAt: DateTime.utc(2026, 1, 1, 12),
      variant: 3,
    );

    final decoded = QuotaSnapshotModel.fromJson(snapshot.toJson());

    expect(decoded.id, snapshot.id);
    expect(decoded.accountLabel, snapshot.accountLabel);
    expect(decoded.source, snapshot.source);
    expect(decoded.parserConfidence, snapshot.parserConfidence);
    expect(decoded.fiveHourWindow.used, snapshot.fiveHourWindow.used);
    expect(decoded.weeklyWindow.limit, snapshot.weeklyWindow.limit);
    expect(decoded.creditsRemaining, snapshot.creditsRemaining);
    expect(decoded.capturedAt, snapshot.capturedAt);
    expect(decoded.nextSuggestedRefreshAt, snapshot.nextSuggestedRefreshAt);
  });

  test('quota enums serialize as strings', () {
    expect(QuotaSource.mock.storageKey, 'mock');
    expect(quotaSourceFromStorageKey('mock'), QuotaSource.mock);

    expect(ParserConfidence.high.storageKey, 'high');
    expect(parserConfidenceFromStorageKey('high'), ParserConfidence.high);

    expect(QuotaWindowStatus.warning.storageKey, 'warning');
    expect(
      quotaWindowStatusFromStorageKey('warning'),
      QuotaWindowStatus.warning,
    );
  });
}
