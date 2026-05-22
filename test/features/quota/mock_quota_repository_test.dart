import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/quota/data/datasources/mock_quota_datasource.dart';
import 'package:quota_analytics/features/quota/data/repositories/mock_quota_repository.dart';
import 'package:quota_analytics/features/quota/domain/entities/parser_confidence.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MockQuotaRepository returns a mock snapshot', () async {
    final repository = MockQuotaRepository(
      MockQuotaDataSource(
        clock: FixedClock(DateTime.utc(2026, 1, 1, 12)),
        refreshDelay: Duration.zero,
      ),
    );

    final snapshot = await repository.getLatestSnapshot();

    expect(snapshot.accountLabel, 'Mock GPT Account');
    expect(snapshot.source, QuotaSource.mock);
    expect(snapshot.parserConfidence, ParserConfidence.high);
    expect(snapshot.fiveHourWindow.label, '5-hour window');
    expect(snapshot.weeklyWindow.label, 'Weekly window');
  });

  test('refreshSnapshot updates capturedAt and mock values', () async {
    final repository = MockQuotaRepository(
      MockQuotaDataSource(
        clock: _TickingClock(DateTime.utc(2026, 1, 1, 12)),
        refreshDelay: Duration.zero,
      ),
    );

    final first = await repository.getLatestSnapshot();
    final refreshed = await repository.refreshSnapshot();

    expect(refreshed.capturedAt.isAfter(first.capturedAt), isTrue);
    expect(refreshed.id, isNot(first.id));
    expect(refreshed.fiveHourWindow.used, isNot(first.fiveHourWindow.used));
  });
}

class _TickingClock implements Clock {
  _TickingClock(this._current);

  DateTime _current;

  @override
  DateTime now() {
    final value = _current;
    _current = _current.add(const Duration(minutes: 1));
    return value;
  }
}
