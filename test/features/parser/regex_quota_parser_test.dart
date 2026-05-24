import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/parser/data/parsers/regex_quota_parser.dart';
import 'package:quota_analytics/features/parser/domain/entities/quota_window_type.dart';
import 'package:quota_analytics/features/quota/domain/entities/parser_confidence.dart';

void main() {
  late RegexQuotaParser parser;
  late DateTime now;

  setUp(() {
    parser = RegexQuotaParser();
    now = DateTime(2026, 1, 1, 12);
  });

  test('high confidence sample parses five-hour and weekly usage', () {
    final result = parser.parse('''
5-hour usage
Used 12 of 50
38 remaining
resets in 2 hours


Weekly usage
Used 200 of 1000
800 remaining
resets on Monday
''', now: now);

    expect(result.success, isTrue);
    expect(result.confidence, ParserConfidence.high);
    expect(result.errors, isEmpty);

    final fiveHour = _window(result, QuotaWindowType.fiveHour);
    expect(fiveHour.used, 12);
    expect(fiveHour.limit, 50);
    expect(fiveHour.remaining, 38);
    expect(fiveHour.resetAt, now.add(const Duration(hours: 2)));

    final weekly = _window(result, QuotaWindowType.weekly);
    expect(weekly.used, 200);
    expect(weekly.limit, 1000);
    expect(weekly.remaining, 800);
    expect(weekly.resetText, contains('Monday'));
  });

  test('medium confidence sample parses weekly and credits only', () {
    final result = parser.parse('''
Weekly quota
250 remaining of 1000
resets tomorrow
Credit balance: 123 credits
''', now: now);

    expect(result.success, isTrue);
    expect(result.confidence, ParserConfidence.medium);
    expect(result.errors, isEmpty);
    expect(_window(result, QuotaWindowType.weekly).remaining, 250);
    expect(result.credits?.remaining, 123);
  });

  test(
    'low confidence sample records weak signals without structured fields',
    () {
      final result = parser.parse('Usage limit remaining');

      expect(result.success, isTrue);
      expect(result.confidence, ParserConfidence.low);
      expect(result.windows, isEmpty);
      expect(result.warnings, isEmpty);
      expect(result.errors, isEmpty);
    },
  );

  test('failed sample rejects ordinary page text', () {
    final result = parser.parse(
      'Welcome to example.com\nThis page has no quota information.',
    );

    expect(result.success, isFalse);
    expect(result.confidence, ParserConfidence.failed);
    expect(result.windows, isEmpty);
    expect(result.errors, isNotEmpty);
  });

  test('conflict sample does not crash and lowers confidence', () {
    final result = parser.parse('''
Weekly quota
Used 20 of 100
Usage limit details
Used 30 of 100
''');

    expect(result.success, isTrue);
    expect(result.confidence, ParserConfidence.low);
    expect(result.warnings, isNotEmpty);
    expect(_window(result, QuotaWindowType.weekly).used, 20);
  });

  test('redacted sample still parses quota values', () {
    final result = parser.parse('''
[REDACTED_EMAIL]
5h message quota
12 / 50
resets in 5h
[REDACTED_TOKEN]


Weekly quota
76% remaining
''', now: now);

    expect(result.success, isTrue);
    expect(result.confidence, ParserConfidence.high);
    expect(result.matchedSignals, contains('redacted marker present'));
    expect(_window(result, QuotaWindowType.fiveHour).used, 12);
    expect(_window(result, QuotaWindowType.weekly).remainingRatio, 0.76);
  });

  test('Chinese sample parses basic quota labels and values', () {
    final result = parser.parse('''
5小时额度
已使用 10/50
稍后重置


每周额度
剩余 800/1000
重置 周一
''', now: now);

    expect(result.success, isTrue);
    expect(result.confidence, ParserConfidence.high);
    expect(_window(result, QuotaWindowType.fiveHour).used, 10);
    expect(_window(result, QuotaWindowType.weekly).remaining, 800);
    expect(result.warnings, isEmpty);
  });

  test(
    'Chinese Codex analytics sample parses percent remaining and reset time',
    () {
      now = DateTime(2026, 5, 24, 17);
      final result = parser.parse('''
5 小时使用限额

29%
剩余
重置时间：21:58

每周使用限额

89%
剩余
重置时间：2026年5月31日 16:58

剩余额度
0
''', now: now);

      expect(result.success, isTrue);
      expect(result.confidence, ParserConfidence.high);

      final fiveHour = _window(result, QuotaWindowType.fiveHour);
      expect(fiveHour.remainingRatio, 0.29);
      expect(fiveHour.resetAt, DateTime(2026, 5, 24, 21, 58));
      expect(fiveHour.resetText, contains('21:58'));

      final weekly = _window(result, QuotaWindowType.weekly);
      expect(weekly.remainingRatio, 0.89);
      expect(weekly.resetAt, DateTime(2026, 5, 31, 16, 58));
      expect(weekly.resetText, contains('2026年5月31日 16:58'));
    },
  );
}

dynamic _window(dynamic result, QuotaWindowType type) {
  return result.windows.singleWhere((window) => window.type == type);
}
