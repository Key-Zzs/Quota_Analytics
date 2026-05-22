import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extracted_page_text.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_safety_status.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_source.dart';
import 'package:quota_analytics/features/parser/data/mappers/parse_result_to_quota_snapshot_mapper.dart';
import 'package:quota_analytics/features/parser/data/parsers/regex_quota_parser.dart';
import 'package:quota_analytics/features/parser/data/repositories/quota_parser_repository_impl.dart';
import 'package:quota_analytics/features/parser/domain/usecases/save_parsed_quota_snapshot.dart';
import 'package:quota_analytics/features/parser/presentation/controllers/quota_parser_controller.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_persistence_status.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_snapshot.dart';
import 'package:quota_analytics/features/quota/domain/repositories/quota_repository.dart';

void main() {
  test('parseExtractedText reports missing extracted text', () async {
    final controller = _controller();

    await controller.parseExtractedText(null);

    expect(controller.lastResult, isNull);
    expect(controller.lastError, contains('No extracted'));
    expect(controller.lastParserInputLength, 0);
  });

  test(
    'parseExtractedText creates snapshot preview for medium confidence',
    () async {
      final controller = _controller();

      await controller.parseExtractedText(
        _extraction('''
Weekly quota
Used 100 of 500
'''),
      );

      expect(controller.lastResult?.success, isTrue);
      expect(controller.previewSnapshot, isNotNull);
      expect(controller.canSaveParsedSnapshot, isTrue);
    },
  );

  test(
    'saveParsedSnapshot requires explicit call and stores snapshot',
    () async {
      final repository = _FakeQuotaRepository();
      final controller = _controller(repository: repository);

      await controller.parseExtractedText(
        _extraction('''
5-hour window
Used 10 of 50


Weekly window
Used 200 of 1000
'''),
      );

      expect(repository.saved, isNull);

      final saved = await controller.saveParsedSnapshot();

      expect(saved, isNotNull);
      expect(repository.saved, saved);
      expect(controller.lastSavedSnapshot, saved);
    },
  );
}

QuotaParserController _controller({_FakeQuotaRepository? repository}) {
  final quotaRepository = repository ?? _FakeQuotaRepository();
  return QuotaParserController(
    repository: QuotaParserRepositoryImpl(parser: RegexQuotaParser()),
    mapper: const ParseResultToQuotaSnapshotMapper(),
    saveParsedQuotaSnapshot: SaveParsedQuotaSnapshot(quotaRepository),
  );
}

ExtractedPageText _extraction(String text) {
  return ExtractedPageText(
    id: 'manual-webview-1',
    sanitizedUrl: 'https://chatgpt.com/usage',
    pageTitle: 'Usage',
    redactedTextPreview: text,
    originalLength: text.length,
    redactedLength: text.length,
    redactedEmailCount: 0,
    redactedTokenCount: 0,
    redactedApiKeyCount: 0,
    redactedSecretCount: 0,
    truncated: false,
    extractedAt: DateTime(2026, 1, 1, 12),
    source: ExtractionSource.webViewManual,
    safetyStatus: ExtractionSafetyStatus.allowed,
  );
}

class _FakeQuotaRepository implements QuotaRepository {
  QuotaSnapshot? saved;

  @override
  Future<void> clearLocalQuotaData() async {}

  @override
  Future<List<QuotaSnapshot>> getHistory() async {
    return saved == null ? const [] : [saved!];
  }

  @override
  Future<QuotaSnapshot> getLatestSnapshot() async {
    return saved!;
  }

  @override
  Future<QuotaPersistenceStatus> getPersistenceStatus() async {
    return QuotaPersistenceStatus.mockOnly();
  }

  @override
  Future<QuotaSnapshot> refreshSnapshot() async {
    return saved!;
  }

  @override
  Future<QuotaSnapshot> saveSnapshot(QuotaSnapshot snapshot) async {
    saved = snapshot;
    return snapshot;
  }
}
