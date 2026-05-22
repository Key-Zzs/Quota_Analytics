import '../../domain/entities/parser_confidence.dart';
import '../../domain/entities/quota_snapshot.dart';
import '../../domain/entities/quota_source.dart';
import '../../domain/entities/quota_window.dart';

class QuotaSnapshotModel extends QuotaSnapshot {
  const QuotaSnapshotModel({
    required super.id,
    required super.accountLabel,
    required super.source,
    required super.parserConfidence,
    required super.fiveHourWindow,
    required super.weeklyWindow,
    required super.creditsRemaining,
    required super.creditsTotal,
    required super.capturedAt,
    required super.nextSuggestedRefreshAt,
    required super.rawDebugText,
  });

  factory QuotaSnapshotModel.mock({
    required DateTime capturedAt,
    required int variant,
  }) {
    final fiveHourUsed = 58 + (variant % 7);
    final weeklyUsed = 742 + ((variant * 11) % 48);
    final creditsRemaining = 42.5 - (variant * 0.25);

    return QuotaSnapshotModel(
      id: 'mock-${capturedAt.microsecondsSinceEpoch}-$variant',
      accountLabel: 'Mock GPT Account',
      source: QuotaSource.mock,
      parserConfidence: ParserConfidence.high,
      fiveHourWindow: QuotaWindow.fromUsage(
        label: '5-hour window',
        used: fiveHourUsed,
        limit: 100,
        resetAt: capturedAt.add(const Duration(hours: 2, minutes: 35)),
      ),
      weeklyWindow: QuotaWindow.fromUsage(
        label: 'Weekly window',
        used: weeklyUsed,
        limit: 1000,
        resetAt: capturedAt.add(const Duration(days: 3, hours: 4)),
      ),
      creditsRemaining: creditsRemaining < 0 ? 0 : creditsRemaining,
      creditsTotal: 50,
      capturedAt: capturedAt,
      nextSuggestedRefreshAt: capturedAt.add(const Duration(minutes: 15)),
      rawDebugText:
          'Mock usage text only. Stage 1 does not read real account pages.',
    );
  }
}
