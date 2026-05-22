import 'extraction_safety_status.dart';
import 'extraction_source.dart';

class ExtractedPageText {
  const ExtractedPageText({
    required this.id,
    required this.sanitizedUrl,
    required this.pageTitle,
    required this.redactedTextPreview,
    required this.originalLength,
    required this.redactedLength,
    required this.redactedEmailCount,
    required this.redactedTokenCount,
    required this.redactedApiKeyCount,
    required this.redactedSecretCount,
    required this.truncated,
    required this.extractedAt,
    required this.source,
    required this.safetyStatus,
    this.errorMessage,
  });

  final String id;
  final String sanitizedUrl;
  final String pageTitle;
  final String redactedTextPreview;
  final int originalLength;
  final int redactedLength;
  final int redactedEmailCount;
  final int redactedTokenCount;
  final int redactedApiKeyCount;
  final int redactedSecretCount;
  final bool truncated;
  final DateTime extractedAt;
  final ExtractionSource source;
  final ExtractionSafetyStatus safetyStatus;
  final String? errorMessage;

  bool get hasPreview => redactedTextPreview.trim().isNotEmpty;
  bool get isSuccess => safetyStatus == ExtractionSafetyStatus.allowed;
}
