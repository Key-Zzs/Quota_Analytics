class ParsedCredits {
  const ParsedCredits({this.remaining, this.total, this.rawText});

  final double? remaining;
  final double? total;
  final String? rawText;

  bool get hasValue => remaining != null || total != null;
}
