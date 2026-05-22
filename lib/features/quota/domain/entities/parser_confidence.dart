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
}
