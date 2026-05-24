import '../../../../core/security/text_redactor.dart';
import '../../../../core/serialization/date_time_converter.dart';
import '../../../extraction/data/models/extracted_page_text_model.dart';
import '../../../extraction/domain/entities/extracted_page_text.dart';
import '../../../extraction/domain/entities/extraction_safety_status.dart';
import '../../../parser/domain/entities/parsed_credits.dart';
import '../../../parser/domain/entities/parsed_quota_window.dart';
import '../../../parser/domain/entities/quota_parse_result.dart';
import '../../../parser/domain/entities/quota_window_type.dart';
import '../../../quota/data/models/quota_snapshot_model.dart';
import '../../../quota/domain/entities/parser_confidence.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../domain/entities/manual_refresh_result.dart';
import '../../domain/entities/manual_refresh_status.dart';
import '../../domain/entities/reload_before_refresh_result.dart';

class ManualRefreshResultModel extends ManualRefreshResult {
  const ManualRefreshResultModel({
    required super.status,
    required super.safetyStatus,
    required super.parserConfidence,
    required super.extractedPageText,
    required super.parseResult,
    required super.snapshotCandidate,
    required super.redactionSummary,
    required super.warnings,
    required super.errors,
    required super.startedAt,
    required super.finishedAt,
    required super.savedSnapshotId,
    super.reloadBeforeRefreshResult,
  });

  factory ManualRefreshResultModel.fromEntity(ManualRefreshResult result) {
    return ManualRefreshResultModel(
      status: result.status,
      safetyStatus: result.safetyStatus,
      parserConfidence: result.parserConfidence,
      extractedPageText: result.extractedPageText,
      parseResult: result.parseResult,
      snapshotCandidate: result.snapshotCandidate,
      redactionSummary: result.redactionSummary,
      warnings: result.warnings,
      errors: result.errors,
      startedAt: result.startedAt,
      finishedAt: result.finishedAt,
      savedSnapshotId: result.savedSnapshotId,
      reloadBeforeRefreshResult: result.reloadBeforeRefreshResult,
    );
  }

  factory ManualRefreshResultModel.fromJson(Map<String, Object?> json) {
    final startedAt =
        dateTimeFromIso8601(json['startedAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    return ManualRefreshResultModel(
      status: manualRefreshStatusFromStorageKey(_readString(json['status'])),
      safetyStatus: _readSafetyStatus(json['safetyStatus']),
      parserConfidence: parserConfidenceFromStorageKey(
        _readString(json['parserConfidence']),
      ),
      extractedPageText: _readExtraction(json['extractedPageText']),
      parseResult: _readParseResult(json['parseResult']),
      snapshotCandidate: _readSnapshot(json['snapshotCandidate']),
      redactionSummary: _readRedactionSummary(json['redactionSummary']),
      warnings: _readStringList(json['warnings']),
      errors: _readStringList(json['errors']),
      startedAt: startedAt,
      finishedAt: dateTimeFromIso8601(json['finishedAt']),
      savedSnapshotId: _readNullableString(json['savedSnapshotId']),
      reloadBeforeRefreshResult: _readReloadResult(
        json['reloadBeforeRefreshResult'],
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'status': status.storageKey,
      'safetyStatus': safetyStatus.name,
      'parserConfidence': parserConfidence.storageKey,
      'extractedPageText': extractedPageText == null
          ? null
          : ExtractedPageTextModel.fromEntity(extractedPageText!).toJson(),
      'parseResult': parseResult == null
          ? null
          : _parseResultToJson(parseResult!),
      'snapshotCandidate': snapshotCandidate == null
          ? null
          : QuotaSnapshotModel.fromEntity(snapshotCandidate!).toJson(),
      'redactionSummary': redactionSummary?.toJson(),
      'warnings': warnings,
      'errors': errors,
      'startedAt': dateTimeToIso8601(startedAt),
      'finishedAt': dateTimeToIso8601(finishedAt),
      'savedSnapshotId': savedSnapshotId,
      'reloadBeforeRefreshResult': reloadBeforeRefreshResult?.toJson(),
    };
  }

  static Map<String, Object?> _parseResultToJson(QuotaParseResult result) {
    return {
      'success': result.success,
      'confidence': result.confidence.storageKey,
      'windows': result.windows.map(_windowToJson).toList(growable: false),
      'credits': result.credits == null
          ? null
          : {
              'remaining': result.credits!.remaining,
              'total': result.credits!.total,
              'rawText': result.credits!.rawText,
            },
      'matchedSignals': result.matchedSignals,
      'warnings': result.warnings,
      'errors': result.errors,
      'parsedAt': dateTimeToIso8601(result.parsedAt),
      'parserVersion': result.parserVersion,
    };
  }

  static Map<String, Object?> _windowToJson(ParsedQuotaWindow window) {
    return {
      'type': window.type.name,
      'used': window.used,
      'limit': window.limit,
      'remaining': window.remaining,
      'remainingRatio': window.remainingRatio,
      'resetAt': dateTimeToIso8601(window.resetAt),
      'resetText': window.resetText,
      'evidenceLabels': window.evidenceLabels,
    };
  }

  static QuotaParseResult? _readParseResult(Object? value) {
    final json = _readMap(value);
    if (json == null) {
      return null;
    }
    return QuotaParseResult(
      success: _readBool(json['success']),
      confidence: parserConfidenceFromStorageKey(
        _readString(json['confidence']),
      ),
      windows: _readList(
        json['windows'],
      ).map(_readWindow).whereType<ParsedQuotaWindow>().toList(growable: false),
      credits: _readCredits(json['credits']),
      matchedSignals: _readStringList(json['matchedSignals']),
      warnings: _readStringList(json['warnings']),
      errors: _readStringList(json['errors']),
      parsedAt:
          dateTimeFromIso8601(json['parsedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      parserVersion:
          _readString(json['parserVersion']) ?? 'regex-quota-parser-v1',
    );
  }

  static ParsedQuotaWindow? _readWindow(Object? value) {
    final json = _readMap(value);
    if (json == null) {
      return null;
    }
    return ParsedQuotaWindow(
      type: _readWindowType(json['type']),
      used: _readInt(json['used']),
      limit: _readInt(json['limit']),
      remaining: _readInt(json['remaining']),
      remainingRatio: _readDouble(json['remainingRatio']),
      resetAt: dateTimeFromIso8601(json['resetAt']),
      resetText: _readNullableString(json['resetText']),
      evidenceLabels: _readStringList(json['evidenceLabels']),
    );
  }

  static ParsedCredits? _readCredits(Object? value) {
    final json = _readMap(value);
    if (json == null) {
      return null;
    }
    return ParsedCredits(
      remaining: _readDouble(json['remaining']),
      total: _readDouble(json['total']),
      rawText: _readNullableString(json['rawText']),
    );
  }

  static ExtractedPageText? _readExtraction(Object? value) {
    final json = _readMap(value);
    return json == null ? null : ExtractedPageTextModel.fromJson(json);
  }

  static QuotaSnapshot? _readSnapshot(Object? value) {
    final json = _readMap(value);
    return json == null ? null : QuotaSnapshotModel.fromJson(json);
  }

  static RedactionSummary? _readRedactionSummary(Object? value) {
    final json = _readMap(value);
    if (json == null) {
      return null;
    }
    return RedactionSummary(
      originalLength: _readInt(json['originalLength']) ?? 0,
      redactedLength: _readInt(json['redactedLength']) ?? 0,
      redactedEmailCount: _readInt(json['redactedEmailCount']) ?? 0,
      redactedTokenCount: _readInt(json['redactedTokenCount']) ?? 0,
      redactedApiKeyCount: _readInt(json['redactedApiKeyCount']) ?? 0,
      redactedSecretCount: _readInt(json['redactedSecretCount']) ?? 0,
      truncated: _readBool(json['truncated']),
    );
  }

  static ReloadBeforeRefreshResult? _readReloadResult(Object? value) {
    final json = _readMap(value);
    return json == null ? null : ReloadBeforeRefreshResult.fromJson(json);
  }

  static ExtractionSafetyStatus _readSafetyStatus(Object? value) {
    final text = _readString(value);
    return ExtractionSafetyStatus.values.firstWhere(
      (status) => status.name == text,
      orElse: () => ExtractionSafetyStatus.failed,
    );
  }

  static QuotaWindowType _readWindowType(Object? value) {
    final text = _readString(value);
    return QuotaWindowType.values.firstWhere(
      (type) => type.name == text,
      orElse: () => QuotaWindowType.unknown,
    );
  }

  static String? _readString(Object? value) {
    return value is String ? value : null;
  }

  static String? _readNullableString(Object? value) {
    final text = _readString(value)?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static List<Object?> _readList(Object? value) {
    return value is List ? value : const [];
  }

  static List<String> _readStringList(Object? value) {
    return _readList(value).whereType<String>().toList(growable: false);
  }

  static Map<String, Object?>? _readMap(Object? value) {
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
    }
    return null;
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  static bool _readBool(Object? value) {
    return value is bool && value;
  }
}
