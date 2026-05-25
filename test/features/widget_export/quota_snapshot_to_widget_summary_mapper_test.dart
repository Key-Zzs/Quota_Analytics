import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';
import 'package:quota_analytics/features/quota/domain/entities/parser_confidence.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_snapshot.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_source.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_window.dart';
import 'package:quota_analytics/features/widget_export/data/mappers/quota_snapshot_to_widget_summary_mapper.dart';

void main() {
  final now = DateTime.utc(2026, 5, 26, 10, 30);
  final mapper = QuotaSnapshotToWidgetSummaryMapper();

  test('maps five-hour weekly reset credits source and confidence', () {
    final snapshot = _snapshot(
      capturedAt: now.subtract(const Duration(minutes: 5)),
      fiveHourRatio: 0.7,
      weeklyRatio: 0.5,
      creditsRemaining: 23,
    );

    final summary = mapper.map(snapshot, clock: FixedClock(now));

    expect(summary.fiveHourRemainingRatio, 0.7);
    expect(summary.weeklyRemainingRatio, 0.5);
    expect(summary.fiveHourResetAt, snapshot.fiveHourWindow.resetAt);
    expect(summary.weeklyResetAt, snapshot.weeklyWindow.resetAt);
    expect(summary.fiveHourResetText, 'Reset time available');
    expect(summary.weeklyResetText, 'Reset time available');
    expect(summary.creditsRemaining, 23);
    expect(summary.lastUpdatedAt, snapshot.capturedAt);
    expect(summary.source, 'webViewManualExtraction');
    expect(summary.parserConfidence, 'high');
    expect(summary.isStale, isFalse);
    expect(summary.staleReason, 'fresh');
    expect(summary.statusLabel, 'OK');
    expect(summary.errorLabel, isNull);
  });

  test('missing fields do not crash and produce unknown/no data labels', () {
    final snapshot = _snapshot(
      capturedAt: now,
      fiveHourRatio: null,
      weeklyRatio: null,
      creditsRemaining: null,
      includeFiveHourResetAt: false,
      includeWeeklyResetAt: false,
    );

    final summary = mapper.map(snapshot, clock: FixedClock(now));

    expect(summary.fiveHourRemainingRatio, isNull);
    expect(summary.weeklyRemainingRatio, isNull);
    expect(summary.fiveHourResetText, 'Reset time unknown');
    expect(summary.weeklyResetText, 'Reset time unknown');
    expect(summary.statusLabel, 'UNKNOWN');
    expect(summary.errorLabel, 'No data');
  });

  test('stale and fresh snapshots are classified by age', () {
    final stale = mapper.map(
      _snapshot(capturedAt: now.subtract(const Duration(minutes: 31))),
      clock: FixedClock(now),
    );
    final fresh = mapper.map(
      _snapshot(capturedAt: now.subtract(const Duration(minutes: 29))),
      clock: FixedClock(now),
    );

    expect(stale.isStale, isTrue);
    expect(stale.staleReason, 'stale_by_age');
    expect(stale.statusLabel, 'STALE');
    expect(stale.displaySubtitle, 'Stale data');
    expect(fresh.isStale, isFalse);
    expect(fresh.staleReason, 'fresh');
  });

  test('low quota status is conservative', () {
    final summary = mapper.map(
      _snapshot(capturedAt: now, fiveHourRatio: 0.24, weeklyRatio: 0.8),
      clock: FixedClock(now),
    );

    expect(summary.statusLabel, 'LOW');
  });

  test('does not copy raw debug text extracted text or account email', () {
    final snapshot = _snapshot(
      capturedAt: now,
      accountLabel: 'person@example.com',
      rawDebugText:
          'document.body.innerText raw page text token=secret person@example.com',
    );

    final summary = mapper.map(snapshot, clock: FixedClock(now));
    final exportedValues = [
      summary.id,
      summary.source,
      summary.parserConfidence,
      summary.displayTitle,
      summary.displaySubtitle,
      summary.fiveHourResetText,
      summary.weeklyResetText,
      summary.statusLabel,
      summary.errorLabel,
      summary.staleReason,
    ].whereType<String>().join(' ');

    expect(exportedValues, isNot(contains('document.body')));
    expect(exportedValues, isNot(contains('raw page text')));
    expect(exportedValues, isNot(contains('token=secret')));
    expect(exportedValues, isNot(contains('person@example.com')));
  });
}

QuotaSnapshot _snapshot({
  required DateTime capturedAt,
  double? fiveHourRatio = 0.7,
  double? weeklyRatio = 0.6,
  double? creditsRemaining = 10,
  bool includeFiveHourResetAt = true,
  bool includeWeeklyResetAt = true,
  String accountLabel = 'Safe account',
  String? rawDebugText = 'safe debug',
}) {
  return QuotaSnapshotModel(
    id: 'snapshot-${capturedAt.microsecondsSinceEpoch}',
    accountLabel: accountLabel,
    source: QuotaSource.webViewManualExtraction,
    parserConfidence: ParserConfidence.high,
    fiveHourWindow: QuotaWindow(
      label: '5-hour window',
      used: null,
      limit: null,
      remaining: null,
      remainingRatio: fiveHourRatio,
      resetAt: includeFiveHourResetAt
          ? capturedAt.add(const Duration(hours: 2))
          : null,
      status: QuotaWindow.statusForRemainingRatio(fiveHourRatio),
    ),
    weeklyWindow: QuotaWindow(
      label: 'Weekly window',
      used: null,
      limit: null,
      remaining: null,
      remainingRatio: weeklyRatio,
      resetAt: includeWeeklyResetAt
          ? capturedAt.add(const Duration(days: 2))
          : null,
      status: QuotaWindow.statusForRemainingRatio(weeklyRatio),
    ),
    creditsRemaining: creditsRemaining,
    creditsTotal: 50,
    capturedAt: capturedAt,
    nextSuggestedRefreshAt: null,
    rawDebugText: rawDebugText,
  );
}
