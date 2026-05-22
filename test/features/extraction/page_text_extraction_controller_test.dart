import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extracted_page_text.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_safety_status.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_source.dart';
import 'package:quota_analytics/features/extraction/domain/repositories/page_text_extraction_repository.dart';
import 'package:quota_analytics/features/extraction/presentation/controllers/page_text_extraction_controller.dart';

void main() {
  test('initial state is empty', () {
    final controller = PageTextExtractionController(
      repository: _FakeExtractionRepository(),
    );

    expect(controller.lastExtraction, isNull);
    expect(controller.isExtracting, isFalse);
    expect(controller.hasCachedText, isFalse);
  });

  test('extraction success updates state', () async {
    final result = _extraction(
      safetyStatus: ExtractionSafetyStatus.allowed,
      redactedTextPreview: 'Usage [REDACTED_EMAIL]',
    );
    final controller = PageTextExtractionController(
      repository: _FakeExtractionRepository(extractResult: result),
    );

    await controller.extractCurrentPageText();

    expect(controller.lastExtraction, result);
    expect(controller.message, 'Page text extracted and redacted.');
    expect(controller.lastError, isNull);
    expect(controller.hasCachedText, isTrue);
  });

  test('extraction blocked by URL updates safe status', () async {
    final result = _extraction(
      safetyStatus: ExtractionSafetyStatus.blockedUnknownHost,
      errorMessage:
          'Extraction is blocked because the current host is not allowlisted.',
    );
    final controller = PageTextExtractionController(
      repository: _FakeExtractionRepository(extractResult: result),
    );

    await controller.extractCurrentPageText();

    expect(
      controller.lastExtraction?.safetyStatus,
      ExtractionSafetyStatus.blockedUnknownHost,
    );
    expect(controller.message, 'Extraction blocked: host is not allowlisted.');
    expect(controller.lastError, contains('allowlisted'));
  });

  test('extraction failed records failure', () async {
    final result = _extraction(
      safetyStatus: ExtractionSafetyStatus.failed,
      errorMessage: 'WebView text reader is not ready.',
    );
    final controller = PageTextExtractionController(
      repository: _FakeExtractionRepository(extractResult: result),
    );

    await controller.extractCurrentPageText();

    expect(
      controller.lastExtraction?.safetyStatus,
      ExtractionSafetyStatus.failed,
    );
    expect(controller.message, 'Page text extraction failed.');
    expect(controller.lastError, 'WebView text reader is not ready.');
  });

  test('clear last extracted text resets state', () async {
    final repository = _FakeExtractionRepository(
      loadResult: _extraction(
        safetyStatus: ExtractionSafetyStatus.allowed,
        redactedTextPreview: 'preview',
      ),
    );
    final controller = PageTextExtractionController(repository: repository);

    await controller.loadLastExtractedPageText();
    expect(controller.hasCachedText, isTrue);

    await controller.clearExtractedPageText();

    expect(repository.cleared, isTrue);
    expect(controller.lastExtraction, isNull);
    expect(controller.hasCachedText, isFalse);
  });
}

ExtractedPageText _extraction({
  required ExtractionSafetyStatus safetyStatus,
  String redactedTextPreview = '',
  String? errorMessage,
}) {
  return ExtractedPageText(
    id: 'manual-webview-1',
    sanitizedUrl: 'https://chatgpt.com/settings',
    pageTitle: 'Settings',
    redactedTextPreview: redactedTextPreview,
    originalLength: redactedTextPreview.length,
    redactedLength: redactedTextPreview.length,
    redactedEmailCount: 0,
    redactedTokenCount: 0,
    redactedApiKeyCount: 0,
    redactedSecretCount: 0,
    truncated: false,
    extractedAt: DateTime(2026, 1, 1, 12),
    source: ExtractionSource.webViewManual,
    safetyStatus: safetyStatus,
    errorMessage: errorMessage,
  );
}

class _FakeExtractionRepository implements PageTextExtractionRepository {
  _FakeExtractionRepository({this.loadResult, this.extractResult});

  final ExtractedPageText? loadResult;
  final ExtractedPageText? extractResult;
  bool cleared = false;

  @override
  void attachPageTextReader(CurrentPageTextReader reader) {}

  @override
  Future<void> clearExtractedPageText() async {
    cleared = true;
  }

  @override
  Future<ExtractedPageText> extractCurrentPageText() async {
    return extractResult ??
        _extraction(safetyStatus: ExtractionSafetyStatus.allowed);
  }

  @override
  Future<ExtractedPageText?> getLastExtractedPageText() async {
    return loadResult;
  }
}
