import '../../domain/entities/quota_parse_result.dart';
import '../../domain/repositories/quota_parser_repository.dart';

class QuotaParserRepositoryImpl implements QuotaParserRepository {
  const QuotaParserRepositoryImpl({required this.parser});

  final QuotaParser parser;

  @override
  QuotaParseResult parse(String text, {DateTime? now}) {
    return parser.parse(text, now: now);
  }
}
