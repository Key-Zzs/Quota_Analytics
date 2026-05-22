class TextLine {
  const TextLine({
    required this.index,
    required this.original,
    required this.normalized,
  });

  final int index;
  final String original;
  final String normalized;
}

String normalizeWhitespace(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<TextLine> splitNormalizedLines(String text) {
  final normalizedNewlines = text
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');
  final lines = <TextLine>[];
  var originalIndex = 0;

  for (final rawLine in normalizedNewlines.split('\n')) {
    final original = normalizeWhitespace(rawLine);
    if (original.isEmpty) {
      originalIndex += 1;
      continue;
    }
    lines.add(
      TextLine(
        index: originalIndex,
        original: original,
        normalized: original.toLowerCase(),
      ),
    );
    originalIndex += 1;
  }

  return lines;
}
