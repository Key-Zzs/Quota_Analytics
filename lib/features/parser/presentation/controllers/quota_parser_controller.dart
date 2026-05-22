import 'package:flutter/foundation.dart';

import '../../../../core/security/sensitive_data_policy.dart';
import '../../../extraction/domain/entities/extracted_page_text.dart';
import '../../../quota/domain/entities/parser_confidence.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../data/mappers/parse_result_to_quota_snapshot_mapper.dart';
import '../../domain/entities/quota_parse_result.dart';
import '../../domain/repositories/quota_parser_repository.dart';
import '../../domain/usecases/parse_extracted_quota_text.dart';
import '../../domain/usecases/save_parsed_quota_snapshot.dart';

class QuotaParserController extends ChangeNotifier {
  QuotaParserController({
    required QuotaParserRepository repository,
    required ParseResultToQuotaSnapshotMapper mapper,
    SaveParsedQuotaSnapshot? saveParsedQuotaSnapshot,
  }) : _parseExtractedQuotaText = ParseExtractedQuotaText(repository),
       _mapper = mapper,
       _saveParsedQuotaSnapshot = saveParsedQuotaSnapshot;

  final ParseExtractedQuotaText _parseExtractedQuotaText;
  final ParseResultToQuotaSnapshotMapper _mapper;
  final SaveParsedQuotaSnapshot? _saveParsedQuotaSnapshot;

  QuotaParseResult? _lastResult;
  QuotaSnapshot? _previewSnapshot;
  QuotaSnapshot? _lastSavedSnapshot;
  bool _isParsing = false;
  bool _isSaving = false;
  int _lastParserInputLength = 0;
  String? _lastError;
  String? _message;

  QuotaParseResult? get lastResult => _lastResult;
  QuotaSnapshot? get previewSnapshot => _previewSnapshot;
  QuotaSnapshot? get lastSavedSnapshot => _lastSavedSnapshot;
  bool get isParsing => _isParsing;
  bool get isSaving => _isSaving;
  int get lastParserInputLength => _lastParserInputLength;
  String? get lastError => _lastError;
  String? get message => _message;
  bool get canSaveParsedSnapshot {
    return !_isSaving &&
        _previewSnapshot != null &&
        _lastResult?.canCreateSnapshot == true &&
        _saveParsedQuotaSnapshot != null;
  }

  Future<void> parseExtractedText(ExtractedPageText? extraction) async {
    if (_isParsing) {
      return;
    }

    final input = extraction?.redactedTextPreview ?? '';
    if (input.trim().isEmpty) {
      _lastParserInputLength = 0;
      _lastResult = null;
      _previewSnapshot = null;
      _lastError = 'No extracted redacted text is available to parse.';
      _message = 'Extract page text before parsing.';
      notifyListeners();
      return;
    }

    _isParsing = true;
    _lastError = null;
    _message = null;
    notifyListeners();

    try {
      _lastParserInputLength = input.length;
      final result = _parseExtractedQuotaText(input);
      _lastResult = result;
      _previewSnapshot = _mapper.map(result);
      _message = result.canCreateSnapshot
          ? 'Parsed quota text. Review the preview before saving.'
          : 'Parsed quota text with ${result.confidence.label} confidence.';
    } on Object catch (error) {
      _lastResult = null;
      _previewSnapshot = null;
      _lastError = SensitiveDataPolicy.sanitizeLogText(error.toString());
      _message = 'Quota parsing failed.';
    } finally {
      _isParsing = false;
      notifyListeners();
    }
  }

  Future<QuotaSnapshot?> saveParsedSnapshot() async {
    if (!canSaveParsedSnapshot) {
      _message = 'Parsed snapshot is not ready to save.';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _lastError = null;
    notifyListeners();

    try {
      final saved = await _saveParsedQuotaSnapshot!(_previewSnapshot!);
      _lastSavedSnapshot = saved;
      _message = 'Parsed snapshot saved locally.';
      return saved;
    } on Object catch (error) {
      _lastError = SensitiveDataPolicy.sanitizeLogText(error.toString());
      _message = 'Unable to save parsed snapshot.';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearParseResult() {
    _lastResult = null;
    _previewSnapshot = null;
    _lastSavedSnapshot = null;
    _lastParserInputLength = 0;
    _lastError = null;
    _message = 'Parser result cleared.';
    notifyListeners();
  }
}
