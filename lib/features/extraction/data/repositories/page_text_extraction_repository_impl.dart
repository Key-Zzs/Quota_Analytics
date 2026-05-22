import '../../../../core/security/allowed_web_hosts.dart';
import '../../../../core/security/sensitive_data_policy.dart';
import '../../../../core/security/text_redactor.dart';
import '../../../../core/security/url_sanitizer.dart';
import '../../../../core/time/clock.dart';
import '../../domain/entities/extracted_page_text.dart';
import '../../domain/entities/extraction_safety_status.dart';
import '../../domain/entities/extraction_source.dart';
import '../../domain/repositories/page_text_extraction_repository.dart';
import '../datasources/local_extracted_text_datasource.dart';
import '../models/extracted_page_text_model.dart';

class PageTextExtractionRepositoryImpl implements PageTextExtractionRepository {
  PageTextExtractionRepositoryImpl({
    required this.localDataSource,
    required this.clock,
    TextRedactor redactor = const TextRedactor(),
  }) : _redactor = redactor;

  final LocalExtractedTextDataSource localDataSource;
  final Clock clock;
  final TextRedactor _redactor;

  CurrentPageTextReader? _pageTextReader;

  @override
  void attachPageTextReader(CurrentPageTextReader reader) {
    _pageTextReader = reader;
  }

  @override
  Future<ExtractedPageText?> getLastExtractedPageText() {
    return localDataSource.loadLast();
  }

  @override
  Future<ExtractedPageText> extractCurrentPageText() async {
    final reader = _pageTextReader;
    if (reader == null) {
      return _saveAndReturn(
        _failure(
          sanitizedUrl: 'none',
          status: ExtractionSafetyStatus.failed,
          errorMessage: 'WebView text reader is not ready.',
        ),
      );
    }

    try {
      final rawUrl = await reader.currentUrl();
      final decision = AllowedWebHosts.evaluate(rawUrl);
      if (!decision.isAllowed) {
        return _saveAndReturn(
          _failure(
            sanitizedUrl: decision.sanitizedUrl,
            status: _mapSafetyStatus(decision.status),
            errorMessage: decision.message,
          ),
        );
      }

      final rawText = await reader.readBodyInnerText();
      final redacted = _redactor.redact(
        rawText,
        maxLength: TextRedactor.persistedPreviewMaxLength,
      );
      final title = _redactor.redact(
        await reader.pageTitle() ?? 'none',
        maxLength: 160,
      );

      return _saveAndReturn(
        ExtractedPageTextModel(
          id: _newId(),
          sanitizedUrl: decision.sanitizedUrl,
          pageTitle: _safeTitle(title.text),
          redactedTextPreview: redacted.text,
          originalLength: redacted.summary.originalLength,
          redactedLength: redacted.summary.redactedLength,
          redactedEmailCount: redacted.summary.redactedEmailCount,
          redactedTokenCount: redacted.summary.redactedTokenCount,
          redactedApiKeyCount: redacted.summary.redactedApiKeyCount,
          redactedSecretCount: redacted.summary.redactedSecretCount,
          truncated: redacted.summary.truncated,
          extractedAt: clock.now(),
          source: ExtractionSource.webViewManual,
          safetyStatus: ExtractionSafetyStatus.allowed,
        ),
      );
    } on Object catch (error) {
      return _saveAndReturn(
        _failure(
          sanitizedUrl: await _safeCurrentUrl(reader),
          status: ExtractionSafetyStatus.failed,
          errorMessage: _safeError(error),
        ),
      );
    }
  }

  @override
  Future<void> clearExtractedPageText() {
    return localDataSource.clear();
  }

  Future<ExtractedPageText> _saveAndReturn(ExtractedPageTextModel model) async {
    await localDataSource.saveLast(model);
    return model;
  }

  ExtractedPageTextModel _failure({
    required String sanitizedUrl,
    required ExtractionSafetyStatus status,
    required String errorMessage,
  }) {
    return ExtractedPageTextModel(
      id: _newId(),
      sanitizedUrl: sanitizedUrl,
      pageTitle: 'none',
      redactedTextPreview: '',
      originalLength: 0,
      redactedLength: 0,
      redactedEmailCount: 0,
      redactedTokenCount: 0,
      redactedApiKeyCount: 0,
      redactedSecretCount: 0,
      truncated: false,
      extractedAt: clock.now(),
      source: ExtractionSource.webViewManual,
      safetyStatus: status,
      errorMessage: errorMessage,
    );
  }

  String _newId() {
    return 'manual-webview-${clock.now().microsecondsSinceEpoch}';
  }

  String _safeTitle(String value) {
    final sanitized = SensitiveDataPolicy.sanitizeLogText(value).trim();
    return sanitized.isEmpty ? 'none' : sanitized;
  }

  Future<String> _safeCurrentUrl(CurrentPageTextReader reader) async {
    try {
      return UrlSanitizer.sanitizeForDisplay(await reader.currentUrl());
    } on Object {
      return 'none';
    }
  }

  String _safeError(Object error) {
    final sanitized = SensitiveDataPolicy.sanitizeLogText(error.toString());
    return _redactor.redact(sanitized, maxLength: 300).text;
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
