import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extracted_page_text.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_safety_status.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_source.dart';
import 'package:quota_analytics/features/extraction/domain/repositories/page_text_extraction_repository.dart';
import 'package:quota_analytics/features/extraction/presentation/controllers/page_text_extraction_controller.dart';
import 'package:quota_analytics/features/extraction/presentation/widgets/extraction_status_card.dart';
import 'package:quota_analytics/features/parser/data/mappers/parse_result_to_quota_snapshot_mapper.dart';
import 'package:quota_analytics/features/parser/data/parsers/regex_quota_parser.dart';
import 'package:quota_analytics/features/parser/data/repositories/quota_parser_repository_impl.dart';
import 'package:quota_analytics/features/parser/domain/usecases/save_parsed_quota_snapshot.dart';
import 'package:quota_analytics/features/parser/presentation/controllers/quota_parser_controller.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_persistence_status.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_snapshot.dart';
import 'package:quota_analytics/features/quota/domain/repositories/quota_repository.dart';

void main() {
  testWidgets(
    'Parse button shows disabled prompt when no extracted text exists',
    (tester) async {
      final extractionController = PageTextExtractionController(
        repository: _FakeExtractionRepository(),
      );
      final parserController = _parserController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                ExtractionStatusCard(
                  controller: extractionController,
                  quotaParserController: parserController,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Extract page text before parsing.'), findsOneWidget);
      expect(find.text('Parse Extracted Text'), findsOneWidget);
      final dynamic parseButton = tester.widget(
        find.byKey(const ValueKey('parse-extracted-text-button')),
      );
      expect(parseButton.onPressed, isNull);
    },
  );

  testWidgets(
    'Save Parsed Snapshot is enabled only for high or medium results',
    (tester) async {
      final extractionController = PageTextExtractionController(
        repository: _FakeExtractionRepository(
          extraction: _extraction('''
Weekly quota
Used 100 of 500
'''),
        ),
      );
      await extractionController.extractCurrentPageText();
      final parserController = _parserController();
      await parserController.parseExtractedText(
        extractionController.lastExtraction,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                ExtractionStatusCard(
                  controller: extractionController,
                  quotaParserController: parserController,
                ),
              ],
            ),
          ),
        ),
      );

      final dynamic saveButton = tester.widget(
        find.byKey(const ValueKey('save-parsed-snapshot-button')),
      );
      expect(saveButton.onPressed, isNotNull);

      final lowParserController = _parserController();
      await lowParserController.parseExtractedText(
        _extraction('Usage limit remaining'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                ExtractionStatusCard(
                  controller: extractionController,
                  quotaParserController: lowParserController,
                ),
              ],
            ),
          ),
        ),
      );

      final dynamic disabledSaveButton = tester.widget(
        find.byKey(const ValueKey('save-parsed-snapshot-button')),
      );
      expect(disabledSaveButton.onPressed, isNull);
    },
  );
}

QuotaParserController _parserController() {
  return QuotaParserController(
    repository: QuotaParserRepositoryImpl(parser: RegexQuotaParser()),
    mapper: const ParseResultToQuotaSnapshotMapper(),
    saveParsedQuotaSnapshot: SaveParsedQuotaSnapshot(_FakeQuotaRepository()),
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

class _FakeExtractionRepository implements PageTextExtractionRepository {
  _FakeExtractionRepository({this.extraction});

  final ExtractedPageText? extraction;

  @override
  void attachPageTextReader(CurrentPageTextReader reader) {}

  @override
  Future<void> clearExtractedPageText() async {}

  @override
  Future<ExtractedPageText> extractCurrentPageText() async {
    return extraction ?? _extraction('');
  }

  @override
  Future<ExtractedPageText?> getLastExtractedPageText() async {
    return extraction;
  }
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
