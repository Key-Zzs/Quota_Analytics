import '../entities/quota_parse_result.dart';
import '../repositories/quota_parser_repository.dart';

class ParseExtractedQuotaText {
  const ParseExtractedQuotaText(this.repository);

  final QuotaParserRepository repository;

  QuotaParseResult call(String redactedVisibleText, {DateTime? now}) {
    return repository.parse(redactedVisibleText, now: now);
  }
}
