import '../entities/quota_parse_result.dart';

abstract class QuotaParser {
  QuotaParseResult parse(String text, {DateTime? now});
}

abstract class QuotaParserRepository {
  QuotaParseResult parse(String text, {DateTime? now});
}
