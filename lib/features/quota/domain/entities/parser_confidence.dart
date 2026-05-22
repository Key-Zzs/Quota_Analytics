enum ParserConfidence { high, medium, low, failed, notApplicable }

extension ParserConfidenceLabel on ParserConfidence {
  String get label {
    return switch (this) {
      ParserConfidence.high => 'high',
      ParserConfidence.medium => 'medium',
      ParserConfidence.low => 'low',
      ParserConfidence.failed => 'failed',
      ParserConfidence.notApplicable => 'not applicable',
    };
  }

  String get storageKey => name;
}

ParserConfidence parserConfidenceFromStorageKey(String? value) {
  return ParserConfidence.values.firstWhere(
    (confidence) => confidence.storageKey == value,
    orElse: () => ParserConfidence.notApplicable,
  );
}
