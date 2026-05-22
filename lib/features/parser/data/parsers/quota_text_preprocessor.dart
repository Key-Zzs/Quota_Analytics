import '../../../../core/parsing/text_lines.dart';

class QuotaTextDocument {
  const QuotaTextDocument({required this.lines});

  final List<TextLine> lines;

  String get normalizedText {
    return lines.map((line) => line.normalized).join('\n');
  }

  bool get isEmpty => lines.isEmpty;

  List<TextLine> nearbyLines(int lineIndex, {int radius = 4}) {
    return lines
        .where((line) => (line.index - lineIndex).abs() <= radius)
        .toList(growable: false);
  }
}

class QuotaTextPreprocessor {
  const QuotaTextPreprocessor();

  QuotaTextDocument preprocess(String text) {
    return QuotaTextDocument(lines: splitNormalizedLines(text));
  }
}
