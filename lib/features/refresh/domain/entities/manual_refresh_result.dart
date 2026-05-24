import '../../../../core/security/text_redactor.dart';
import '../../../extraction/domain/entities/extracted_page_text.dart';
import '../../../extraction/domain/entities/extraction_safety_status.dart';
import '../../../parser/domain/entities/quota_parse_result.dart';
import '../../../quota/domain/entities/parser_confidence.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import 'manual_refresh_policy.dart';
import 'manual_refresh_status.dart';

class ManualRefreshResult {
  const ManualRefreshResult({
    required this.status,
    required this.safetyStatus,
    required this.parserConfidence,
    required this.extractedPageText,
    required this.parseResult,
    required this.snapshotCandidate,
    required this.redactionSummary,
    required this.warnings,
    required this.errors,
    required this.startedAt,
    required this.finishedAt,
    required this.savedSnapshotId,
  });

  factory ManualRefreshResult.idle(DateTime now) {
    return ManualRefreshResult(
      status: ManualRefreshStatus.idle,
      safetyStatus: ExtractionSafetyStatus.failed,
      parserConfidence: ParserConfidence.notApplicable,
      extractedPageText: null,
      parseResult: null,
      snapshotCandidate: null,
      redactionSummary: null,
      warnings: const [],
      errors: const [],
      startedAt: now,
      finishedAt: null,
      savedSnapshotId: null,
    );
  }

  final ManualRefreshStatus status;
  final ExtractionSafetyStatus safetyStatus;
  final ParserConfidence parserConfidence;
  final ExtractedPageText? extractedPageText;
  final QuotaParseResult? parseResult;
  final QuotaSnapshot? snapshotCandidate;
  final RedactionSummary? redactionSummary;
  final List<String> warnings;
  final List<String> errors;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String? savedSnapshotId;

  Duration? get duration {
    final finished = finishedAt;
    return finished?.difference(startedAt);
  }

  bool get hasSnapshotCandidate => snapshotCandidate != null;
  bool get isSaved => status == ManualRefreshStatus.saved;

  bool canSaveWith(ManualRefreshPolicy policy) {
    return policy
        .decisionFor(
          confidence: parserConfidence,
          hasSnapshotCandidate: hasSnapshotCandidate,
          parseSucceeded: parseResult?.success ?? false,
        )
        .canSaveManually;
  }

  ManualRefreshResult copyWith({
    ManualRefreshStatus? status,
    ExtractionSafetyStatus? safetyStatus,
    ParserConfidence? parserConfidence,
    ExtractedPageText? extractedPageText,
    QuotaParseResult? parseResult,
    QuotaSnapshot? snapshotCandidate,
    RedactionSummary? redactionSummary,
    List<String>? warnings,
    List<String>? errors,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? savedSnapshotId,
  }) {
    return ManualRefreshResult(
      status: status ?? this.status,
      safetyStatus: safetyStatus ?? this.safetyStatus,
      parserConfidence: parserConfidence ?? this.parserConfidence,
      extractedPageText: extractedPageText ?? this.extractedPageText,
      parseResult: parseResult ?? this.parseResult,
      snapshotCandidate: snapshotCandidate ?? this.snapshotCandidate,
      redactionSummary: redactionSummary ?? this.redactionSummary,
      warnings: warnings ?? this.warnings,
      errors: errors ?? this.errors,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      savedSnapshotId: savedSnapshotId ?? this.savedSnapshotId,
    );
  }
}
