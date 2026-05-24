import '../../../../core/security/allowed_web_hosts.dart';
import '../../../../core/security/sensitive_data_policy.dart';
import '../../../../core/security/text_redactor.dart';
import '../../../../core/time/clock.dart';
import '../../../extraction/domain/entities/extracted_page_text.dart';
import '../../../extraction/domain/entities/extraction_safety_status.dart';
import '../../../extraction/domain/repositories/page_text_extraction_repository.dart';
import '../../../parser/data/mappers/parse_result_to_quota_snapshot_mapper.dart';
import '../../../parser/domain/entities/quota_parse_result.dart';
import '../../../parser/domain/repositories/quota_parser_repository.dart';
import '../../../quota/domain/entities/parser_confidence.dart';
import '../entities/manual_refresh_page_state.dart';
import '../entities/manual_refresh_policy.dart';
import '../entities/manual_refresh_result.dart';
import '../entities/manual_refresh_status.dart';
import '../entities/reload_before_refresh_result.dart';
import '../repositories/manual_refresh_repository.dart';
import 'save_manual_refresh_snapshot.dart';

typedef ManualRefreshProgressCallback =
    void Function(ManualRefreshResult result);

class RefreshQuotaFromWebView {
  const RefreshQuotaFromWebView({
    required this.extractionRepository,
    required this.parserRepository,
    required this.mapper,
    required this.manualRefreshRepository,
    required this.saveManualRefreshSnapshot,
    required this.clock,
  });

  final PageTextExtractionRepository extractionRepository;
  final QuotaParserRepository parserRepository;
  final ParseResultToQuotaSnapshotMapper mapper;
  final ManualRefreshRepository manualRefreshRepository;
  final SaveManualRefreshSnapshot saveManualRefreshSnapshot;
  final Clock clock;

  Future<ManualRefreshResult> call({
    required ManualRefreshPageState pageState,
    required ManualRefreshPolicy policy,
    ReloadBeforeRefreshResult? reloadBeforeRefreshResult,
    ManualRefreshProgressCallback? onProgress,
  }) async {
    final startedAt = clock.now();

    ManualRefreshResult progress(
      ManualRefreshStatus status, {
      ExtractionSafetyStatus safetyStatus = ExtractionSafetyStatus.failed,
      ParserConfidence parserConfidence = ParserConfidence.notApplicable,
      ExtractedPageText? extraction,
      QuotaParseResult? parseResult,
      RedactionSummary? redactionSummary,
      List<String> warnings = const [],
      List<String> errors = const [],
    }) {
      final result = ManualRefreshResult(
        status: status,
        safetyStatus: safetyStatus,
        parserConfidence: parserConfidence,
        extractedPageText: extraction,
        parseResult: parseResult,
        snapshotCandidate: parseResult == null ? null : mapper.map(parseResult),
        redactionSummary: redactionSummary,
        warnings: warnings,
        errors: errors,
        startedAt: startedAt,
        finishedAt: status.isTerminal ? clock.now() : null,
        savedSnapshotId: null,
        reloadBeforeRefreshResult: reloadBeforeRefreshResult,
      );
      onProgress?.call(result);
      return result;
    }

    progress(ManualRefreshStatus.checkingPage);

    if (!pageState.isReady) {
      return _saveFinal(
        progress(
          ManualRefreshStatus.blocked,
          errors: const ['WebView controller is not ready.'],
        ),
      );
    }

    final urlDecision = AllowedWebHosts.evaluate(
      pageState.hasCurrentUrl ? pageState.currentUrl : null,
    );
    if (!urlDecision.isAllowed) {
      return _saveFinal(
        progress(
          ManualRefreshStatus.blocked,
          safetyStatus: _mapSafetyStatus(urlDecision.status),
          errors: [urlDecision.message],
        ),
      );
    }

    if (pageState.isLoading) {
      return _saveFinal(
        progress(
          ManualRefreshStatus.blocked,
          safetyStatus: ExtractionSafetyStatus.failed,
          errors: const ['Current WebView page is still loading.'],
        ),
      );
    }

    ExtractedPageText extraction;
    try {
      progress(
        ManualRefreshStatus.extractingText,
        safetyStatus: ExtractionSafetyStatus.allowed,
      );
      extraction = await extractionRepository.extractCurrentPageText();
    } on Object catch (error) {
      return _saveFinal(
        progress(
          ManualRefreshStatus.extractionFailed,
          errors: [
            'Text extraction failed: ${SensitiveDataPolicy.sanitizeLogText(error.toString())}',
          ],
        ),
      );
    }

    final redactionSummary = _redactionSummaryFor(extraction);
    progress(
      ManualRefreshStatus.redactingText,
      safetyStatus: extraction.safetyStatus,
      extraction: extraction,
      redactionSummary: redactionSummary,
    );

    if (!extraction.safetyStatus.isSuccess) {
      final status = extraction.safetyStatus == ExtractionSafetyStatus.failed
          ? ManualRefreshStatus.extractionFailed
          : ManualRefreshStatus.blocked;
      return _saveFinal(
        progress(
          status,
          safetyStatus: extraction.safetyStatus,
          extraction: extraction,
          redactionSummary: redactionSummary,
          errors: [
            extraction.errorMessage ??
                'Current page failed the extraction safety check.',
          ],
        ),
      );
    }

    if (!extraction.hasPreview) {
      return _saveFinal(
        progress(
          ManualRefreshStatus.extractionFailed,
          safetyStatus: extraction.safetyStatus,
          extraction: extraction,
          redactionSummary: redactionSummary,
          errors: const ['Extracted visible page text was empty.'],
        ),
      );
    }

    QuotaParseResult parseResult;
    try {
      progress(
        ManualRefreshStatus.parsing,
        safetyStatus: extraction.safetyStatus,
        extraction: extraction,
        redactionSummary: redactionSummary,
      );
      parseResult = parserRepository.parse(
        extraction.redactedTextPreview,
        now: clock.now(),
      );
    } on Object catch (error) {
      return _saveFinal(
        progress(
          ManualRefreshStatus.parseFailed,
          safetyStatus: extraction.safetyStatus,
          extraction: extraction,
          redactionSummary: redactionSummary,
          errors: [
            'Quota parser failed: ${SensitiveDataPolicy.sanitizeLogText(error.toString())}',
          ],
        ),
      );
    }

    final snapshotCandidate = mapper.map(parseResult);
    final warnings = <String>[
      ...parseResult.warnings,
      if (redactionSummary.truncated)
        'Redacted text was truncated before parsing.',
    ];
    final errors = <String>[...parseResult.errors];

    if (!parseResult.success ||
        parseResult.confidence == ParserConfidence.failed) {
      return _saveFinal(
        progress(
          ManualRefreshStatus.parseFailed,
          safetyStatus: extraction.safetyStatus,
          parserConfidence: parseResult.confidence,
          extraction: extraction,
          parseResult: parseResult,
          redactionSummary: redactionSummary,
          warnings: warnings,
          errors: errors.isEmpty
              ? const ['Quota parser did not find enough quota signals.']
              : errors,
        ),
      );
    }

    if (parseResult.confidence == ParserConfidence.low) {
      final decision = policy.decisionFor(
        confidence: parseResult.confidence,
        hasSnapshotCandidate: snapshotCandidate != null,
        parseSucceeded: parseResult.success,
      );
      return _saveFinal(
        progress(
          ManualRefreshStatus.lowConfidence,
          safetyStatus: extraction.safetyStatus,
          parserConfidence: parseResult.confidence,
          extraction: extraction,
          parseResult: parseResult,
          redactionSummary: redactionSummary,
          warnings: [...warnings, decision.message],
          errors: errors,
        ),
      );
    }

    if (snapshotCandidate == null) {
      return _saveFinal(
        progress(
          ManualRefreshStatus.parseFailed,
          safetyStatus: extraction.safetyStatus,
          parserConfidence: parseResult.confidence,
          extraction: extraction,
          parseResult: parseResult,
          redactionSummary: redactionSummary,
          warnings: warnings,
          errors: const ['Parsed result did not produce a snapshot candidate.'],
        ),
      );
    }

    final decision = policy.decisionFor(
      confidence: parseResult.confidence,
      hasSnapshotCandidate: true,
      parseSucceeded: parseResult.success,
    );
    final candidateResult = progress(
      decision.shouldAutoSave
          ? ManualRefreshStatus.saving
          : ManualRefreshStatus.awaitingUserConfirmation,
      safetyStatus: extraction.safetyStatus,
      parserConfidence: parseResult.confidence,
      extraction: extraction,
      parseResult: parseResult,
      redactionSummary: redactionSummary,
      warnings: [...warnings, decision.message],
      errors: errors,
    ).copyWith(snapshotCandidate: snapshotCandidate);

    onProgress?.call(candidateResult);

    if (decision.shouldAutoSave) {
      return saveManualRefreshSnapshot(candidateResult, policy: policy);
    }

    return _saveFinal(candidateResult);
  }

  Future<ManualRefreshResult> _saveFinal(ManualRefreshResult result) {
    return manualRefreshRepository.saveLastResult(result);
  }

  RedactionSummary _redactionSummaryFor(ExtractedPageText extraction) {
    return RedactionSummary(
      originalLength: extraction.originalLength,
      redactedLength: extraction.redactedLength,
      redactedEmailCount: extraction.redactedEmailCount,
      redactedTokenCount: extraction.redactedTokenCount,
      redactedApiKeyCount: extraction.redactedApiKeyCount,
      redactedSecretCount: extraction.redactedSecretCount,
      truncated: extraction.truncated,
    );
  }

  ExtractionSafetyStatus _mapSafetyStatus(AllowedWebHostStatus status) {
    return switch (status) {
      AllowedWebHostStatus.allowed => ExtractionSafetyStatus.allowed,
      AllowedWebHostStatus.blockedNonHttps =>
        ExtractionSafetyStatus.blockedNonHttps,
      AllowedWebHostStatus.blockedUnknownHost =>
        ExtractionSafetyStatus.blockedUnknownHost,
      AllowedWebHostStatus.failed => ExtractionSafetyStatus.failed,
    };
  }
}
