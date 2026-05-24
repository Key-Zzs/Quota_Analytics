import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/parser/data/parsers/regex_quota_parser.dart';
import 'package:quota_analytics/features/parser/domain/entities/parsed_quota_window.dart';
import 'package:quota_analytics/features/parser/domain/entities/quota_window_type.dart';
import 'package:quota_analytics/features/parser/presentation/widgets/parse_result_card.dart';
import 'package:quota_analytics/features/parser/presentation/widgets/parsed_window_card.dart';

void main() {
  testWidgets('ParseResultCard displays confidence and warnings', (
    tester,
  ) async {
    final result = RegexQuotaParser().parse('''
Weekly quota
Used 20 of 100
Used 30 of 100
''');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(children: [ParseResultCard(result: result)]),
        ),
      ),
    );

    expect(find.text('Confidence'), findsOneWidget);
    expect(find.text('low'), findsOneWidget);
    expect(find.text('Warnings'), findsOneWidget);
    expect(find.textContaining('conflicting'), findsOneWidget);
  });

  testWidgets('ParsedWindowCard displays five-hour and weekly labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: const [
              ParsedWindowCard(
                window: ParsedQuotaWindow(
                  type: QuotaWindowType.fiveHour,
                  used: 12,
                  limit: 50,
                  remaining: 38,
                  remainingRatio: 0.76,
                  resetAt: null,
                  resetText: 'resets in 2 hours',
                  evidenceLabels: ['5-hour usage'],
                ),
              ),
              ParsedWindowCard(
                window: ParsedQuotaWindow(
                  type: QuotaWindowType.weekly,
                  used: 200,
                  limit: 1000,
                  remaining: 800,
                  remainingRatio: 0.8,
                  resetAt: null,
                  resetText: 'resets on Monday',
                  evidenceLabels: ['Weekly usage'],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('5-hour window'), findsOneWidget);
    expect(find.text('Weekly window'), findsOneWidget);
    expect(find.text('Remaining ratio'), findsNWidgets(2));
    expect(find.text('Reset time'), findsNWidgets(2));
    expect(find.text('Used'), findsNothing);
    expect(find.text('Limit'), findsNothing);
    expect(find.text('Remaining'), findsNothing);
    expect(find.text('Reset at'), findsNothing);
    expect(find.text('Reset text'), findsNothing);
  });
}
