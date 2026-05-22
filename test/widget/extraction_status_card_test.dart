import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extracted_page_text.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_safety_status.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_source.dart';
import 'package:quota_analytics/features/extraction/domain/repositories/page_text_extraction_repository.dart';
import 'package:quota_analytics/features/extraction/presentation/controllers/page_text_extraction_controller.dart';
import 'package:quota_analytics/features/extraction/presentation/widgets/extraction_status_card.dart';

void main() {
  testWidgets('ExtractionStatusCard displays redacted preview', (tester) async {
    final controller = PageTextExtractionController(
      repository: _FakeExtractionRepository(
        extractResult: _extraction(
          redactedTextPreview: 'User [REDACTED_EMAIL]',
        ),
      ),
    );
    await controller.extractCurrentPageText();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [ExtractionStatusCard(controller: controller)],
          ),
        ),
      ),
    );

    expect(find.text('Extract Page Text'), findsOneWidget);
    expect(find.text('User [REDACTED_EMAIL]'), findsOneWidget);
    expect(find.textContaining('No cookies, tokens'), findsOneWidget);
  });
}

ExtractedPageText _extraction({required String redactedTextPreview}) {
  return ExtractedPageText(
    id: 'manual-webview-1',
    sanitizedUrl: 'https://chatgpt.com/settings',
    pageTitle: 'Settings',
    redactedTextPreview: redactedTextPreview,
    originalLength: 28,
    redactedLength: redactedTextPreview.length,
    redactedEmailCount: 1,
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
  _FakeExtractionRepository({required this.extractResult});

  final ExtractedPageText extractResult;

  @override
  void attachPageTextReader(CurrentPageTextReader reader) {}

  @override
  Future<void> clearExtractedPageText() async {}

  @override
  Future<ExtractedPageText> extractCurrentPageText() async {
    return extractResult;
  }

  @override
  Future<ExtractedPageText?> getLastExtractedPageText() async {
    return null;
  }
}
