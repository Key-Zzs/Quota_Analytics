import 'package:flutter/foundation.dart';

import '../../../../core/security/sensitive_data_policy.dart';
import '../../domain/entities/extracted_page_text.dart';
import '../../domain/entities/extraction_safety_status.dart';
import '../../domain/repositories/page_text_extraction_repository.dart';
import '../../domain/usecases/clear_extracted_page_text.dart';
import '../../domain/usecases/extract_current_page_text.dart';
import '../../domain/usecases/get_last_extracted_page_text.dart';

class PageTextExtractionController extends ChangeNotifier {
  PageTextExtractionController({
    required PageTextExtractionRepository repository,
  }) : _repository = repository,
       _extractCurrentPageText = ExtractCurrentPageText(repository),
       _getLastExtractedPageText = GetLastExtractedPageText(repository),
       _clearExtractedPageText = ClearExtractedPageText(repository);

  final PageTextExtractionRepository _repository;
  final ExtractCurrentPageText _extractCurrentPageText;
  final GetLastExtractedPageText _getLastExtractedPageText;
  final ClearExtractedPageText _clearExtractedPageText;

  ExtractedPageText? _lastExtraction;
  bool _isExtracting = false;
  String? _lastError;
  String? _message;

  ExtractedPageText? get lastExtraction => _lastExtraction;
  bool get isExtracting => _isExtracting;
  String? get lastError => _lastError;
  String? get message => _message;
  bool get hasCachedText => _lastExtraction?.hasPreview == true;

  void attachPageTextReader(CurrentPageTextReader reader) {
    _repository.attachPageTextReader(reader);
    notifyListeners();
  }

  Future<void> loadLastExtractedPageText() async {
    try {
      _lastExtraction = await _getLastExtractedPageText();
      _lastError = null;
    } on Object catch (error) {
      _lastError = SensitiveDataPolicy.sanitizeLogText(error.toString());
    }
    notifyListeners();
  }

  Future<void> extractCurrentPageText() async {
    if (_isExtracting) {
      return;
    }

    _isExtracting = true;
    _lastError = null;
    _message = null;
    notifyListeners();

    try {
      final result = await _extractCurrentPageText();
      _lastExtraction = result;
      _lastError = result.errorMessage;
      _message = _messageForResult(result);
    } on Object catch (error) {
      _lastError = SensitiveDataPolicy.sanitizeLogText(error.toString());
      _message = 'Page text extraction failed.';
    } finally {
      _isExtracting = false;
      notifyListeners();
    }
  }

  Future<void> clearExtractedPageText() async {
    await _clearExtractedPageText();
    _lastExtraction = null;
    _lastError = null;
    _message = 'Extracted text cache cleared.';
    notifyListeners();
  }

  String _messageForResult(ExtractedPageText result) {
    return switch (result.safetyStatus) {
      ExtractionSafetyStatus.allowed => 'Page text extracted and redacted.',
      ExtractionSafetyStatus.blockedNonHttps =>
        'Extraction blocked: HTTPS is required.',
      ExtractionSafetyStatus.blockedUnknownHost =>
        'Extraction blocked: host is not allowlisted.',
      ExtractionSafetyStatus.failed => 'Page text extraction failed.',
    };
  }
}
