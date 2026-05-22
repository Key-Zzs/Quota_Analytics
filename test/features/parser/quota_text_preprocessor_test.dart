import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/parser/data/parsers/quota_text_preprocessor.dart';

void main() {
  test('normalizes whitespace and removes empty lines', () {
    const preprocessor = QuotaTextPreprocessor();

    final document = preprocessor.preprocess(
      '  Usage   limit \n\n  Remaining\t38  ',
    );

    expect(document.lines, hasLength(2));
    expect(document.lines.first.original, 'Usage limit');
    expect(document.lines.first.normalized, 'usage limit');
    expect(document.lines.last.original, 'Remaining 38');
  });

  test('nearbyLines returns original line index range', () {
    const preprocessor = QuotaTextPreprocessor();
    final document = preprocessor.preprocess('a\nb\nc\nd\ne');

    final nearby = document.nearbyLines(2, radius: 1);

    expect(nearby.map((line) => line.original), ['b', 'c', 'd']);
  });
}
