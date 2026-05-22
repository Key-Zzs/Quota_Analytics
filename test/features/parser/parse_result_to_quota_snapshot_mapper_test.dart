import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/parser/data/mappers/parse_result_to_quota_snapshot_mapper.dart';
import 'package:quota_analytics/features/parser/data/parsers/regex_quota_parser.dart';
import 'package:quota_analytics/features/parser/domain/entities/quota_window_type.dart';
import 'package:quota_analytics/features/quota/domain/entities/parser_confidence.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_source.dart';

void main() {
  test(
    'maps high confidence parse result to webViewManualExtraction snapshot',
    () {
      final result = RegexQuotaParser().parse('''
5-hour window
Used 10 of 50


Weekly window
800 remaining of 1000
123 credits remaining
''', now: DateTime(2026, 1, 1, 12));

      final snapshot = const ParseResultToQuotaSnapshotMapper().map(result);

      expect(snapshot, isNotNull);
      expect(snapshot!.source, QuotaSource.webViewManualExtraction);
      expect(snapshot.parserConfidence, ParserConfidence.high);
      expect(snapshot.accountLabel, 'WebView Extracted Account');
      expect(snapshot.fiveHourWindow.used, 10);
      expect(snapshot.weeklyWindow.remaining, 800);
      expect(snapshot.rawDebugText, contains('Parser: regex-quota-parser-v1'));
      expect(snapshot.rawDebugText, isNot(contains('document.body')));
    },
  );

  test('does not map low confidence results to snapshots', () {
    final result = RegexQuotaParser().parse('Usage limit remaining');

    final snapshot = const ParseResultToQuotaSnapshotMapper().map(result);

    expect(result.confidence, ParserConfidence.low);
    expect(snapshot, isNull);
  });

  test('keeps missing windows as unknown quota windows', () {
    final result = RegexQuotaParser().parse('''
Weekly quota
Used 100 of 500
''', now: DateTime(2026, 1, 1, 12));

    final snapshot = const ParseResultToQuotaSnapshotMapper().map(result);

    expect(result.confidence, ParserConfidence.medium);
    expect(snapshot?.fiveHourWindow.label, QuotaWindowType.fiveHour.label);
    expect(snapshot?.fiveHourWindow.used, isNull);
    expect(snapshot?.weeklyWindow.used, 100);
  });
}
