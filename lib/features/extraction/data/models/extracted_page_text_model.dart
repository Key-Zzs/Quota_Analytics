import '../../domain/entities/extracted_page_text.dart';
import '../../domain/entities/extraction_safety_status.dart';
import '../../domain/entities/extraction_source.dart';

class ExtractedPageTextModel extends ExtractedPageText {
  const ExtractedPageTextModel({
    required super.id,
    required super.sanitizedUrl,
    required super.pageTitle,
    required super.redactedTextPreview,
    required super.originalLength,
    required super.redactedLength,
    required super.redactedEmailCount,
    required super.redactedTokenCount,
    required super.redactedApiKeyCount,
    required super.redactedSecretCount,
    required super.truncated,
    required super.extractedAt,
    required super.source,
    required super.safetyStatus,
    super.errorMessage,
  });

  factory ExtractedPageTextModel.fromEntity(ExtractedPageText entity) {
    return ExtractedPageTextModel(
      id: entity.id,
      sanitizedUrl: entity.sanitizedUrl,
      pageTitle: entity.pageTitle,
      redactedTextPreview: entity.redactedTextPreview,
      originalLength: entity.originalLength,
      redactedLength: entity.redactedLength,
      redactedEmailCount: entity.redactedEmailCount,
      redactedTokenCount: entity.redactedTokenCount,
      redactedApiKeyCount: entity.redactedApiKeyCount,
      redactedSecretCount: entity.redactedSecretCount,
      truncated: entity.truncated,
      extractedAt: entity.extractedAt,
      source: entity.source,
      safetyStatus: entity.safetyStatus,
      errorMessage: entity.errorMessage,
    );
  }

  factory ExtractedPageTextModel.fromJson(Map<String, Object?> json) {
    return ExtractedPageTextModel(
      id: _readString(json['id'], fallback: 'unknown'),
      sanitizedUrl: _readString(json['sanitizedUrl'], fallback: 'none'),
      pageTitle: _readString(json['pageTitle'], fallback: 'none'),
      redactedTextPreview: _readString(json['redactedTextPreview']),
      originalLength: _readInt(json['originalLength']),
      redactedLength: _readInt(json['redactedLength']),
      redactedEmailCount: _readInt(json['redactedEmailCount']),
      redactedTokenCount: _readInt(json['redactedTokenCount']),
      redactedApiKeyCount: _readInt(json['redactedApiKeyCount']),
      redactedSecretCount: _readInt(json['redactedSecretCount']),
      truncated: _readBool(json['truncated']),
      extractedAt: _readDateTime(json['extractedAt']),
      source: _readSource(json['source']),
      safetyStatus: _readSafetyStatus(json['safetyStatus']),
      errorMessage: _readNullableString(json['errorMessage']),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'sanitizedUrl': sanitizedUrl,
      'pageTitle': pageTitle,
      'redactedTextPreview': redactedTextPreview,
      'originalLength': originalLength,
      'redactedLength': redactedLength,
      'redactedEmailCount': redactedEmailCount,
      'redactedTokenCount': redactedTokenCount,
      'redactedApiKeyCount': redactedApiKeyCount,
      'redactedSecretCount': redactedSecretCount,
      'truncated': truncated,
      'extractedAt': extractedAt.toIso8601String(),
      'source': source.name,
      'safetyStatus': safetyStatus.name,
      'errorMessage': errorMessage,
    };
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String) {
      return value;
    }
    return fallback;
  }

  static String? _readNullableString(Object? value) {
    final text = _readString(value).trim();
    return text.isEmpty ? null : text;
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  static bool _readBool(Object? value) {
    return value is bool && value;
  }

  static DateTime _readDateTime(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static ExtractionSource _readSource(Object? value) {
    if (value is String) {
      for (final source in ExtractionSource.values) {
        if (source.name == value) {
          return source;
        }
      }
    }
    return ExtractionSource.webViewManual;
  }

  static ExtractionSafetyStatus _readSafetyStatus(Object? value) {
    if (value is String) {
      for (final status in ExtractionSafetyStatus.values) {
        if (status.name == value) {
          return status;
        }
      }
    }
    return ExtractionSafetyStatus.failed;
  }
}
