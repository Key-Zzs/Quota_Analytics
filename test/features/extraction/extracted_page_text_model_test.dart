import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/extraction/data/models/extracted_page_text_model.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_safety_status.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_source.dart';

void main() {
  test('JSON round trip keeps fields and enum strings', () {
    final model = ExtractedPageTextModel(
      id: 'manual-webview-1',
      sanitizedUrl: 'https://chatgpt.com/settings',
      pageTitle: 'Settings',
      redactedTextPreview: 'email [REDACTED_EMAIL]',
      originalLength: 24,
      redactedLength: 24,
      redactedEmailCount: 1,
      redactedTokenCount: 0,
      redactedApiKeyCount: 0,
      redactedSecretCount: 0,
      truncated: false,
      extractedAt: DateTime.utc(2026, 1, 1, 12),
      source: ExtractionSource.webViewManual,
      safetyStatus: ExtractionSafetyStatus.allowed,
    );

    final json = model.toJson();

    expect(json['source'], 'webViewManual');
    expect(json['safetyStatus'], 'allowed');
    expect(json['extractedAt'], '2026-01-01T12:00:00.000Z');

    final decoded = ExtractedPageTextModel.fromJson(json);

    expect(decoded.id, model.id);
    expect(decoded.source, ExtractionSource.webViewManual);
    expect(decoded.safetyStatus, ExtractionSafetyStatus.allowed);
    expect(decoded.extractedAt, DateTime.utc(2026, 1, 1, 12));
    expect(decoded.redactedTextPreview, 'email [REDACTED_EMAIL]');
  });
}
