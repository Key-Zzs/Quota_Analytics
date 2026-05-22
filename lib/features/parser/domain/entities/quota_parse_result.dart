import '../../../quota/domain/entities/parser_confidence.dart';
import 'parsed_credits.dart';
import 'parsed_quota_window.dart';

class QuotaParseResult {
  const QuotaParseResult({
    required this.success,
    required this.confidence,
    required this.windows,
    required this.credits,
    required this.matchedSignals,
    required this.warnings,
    required this.errors,
    required this.parsedAt,
    required this.parserVersion,
  });

  factory QuotaParseResult.notRun({
    DateTime? parsedAt,
    String parserVersion = 'regex-quota-parser-v1',
  }) {
    return QuotaParseResult(
      success: false,
      confidence: ParserConfidence.notApplicable,
      windows: const [],
      credits: null,
      matchedSignals: const [],
      warnings: const [],
      errors: const [],
      parsedAt: parsedAt ?? DateTime.now(),
      parserVersion: parserVersion,
    );
  }

  final bool success;
  final ParserConfidence confidence;
  final List<ParsedQuotaWindow> windows;
  final ParsedCredits? credits;
  final List<String> matchedSignals;
  final List<String> warnings;
  final List<String> errors;
  final DateTime parsedAt;
  final String parserVersion;

  bool get canCreateSnapshot {
    return confidence == ParserConfidence.high ||
        confidence == ParserConfidence.medium;
  }
}
