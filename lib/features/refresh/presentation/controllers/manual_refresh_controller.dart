import 'package:flutter/foundation.dart';

import '../../../../core/security/sensitive_data_policy.dart';
import '../../../../core/time/clock.dart';
import '../../data/services/page_load_waiter.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../domain/entities/manual_refresh_page_state.dart';
import '../../domain/entities/manual_refresh_policy.dart';
import '../../domain/entities/manual_refresh_result.dart';
import '../../domain/entities/manual_refresh_status.dart';
import '../../domain/entities/reload_before_refresh_policy.dart';
import '../../domain/entities/reload_before_refresh_result.dart';
import '../../domain/entities/reload_before_refresh_status.dart';
import '../../domain/repositories/manual_refresh_repository.dart';
import '../../domain/usecases/reload_page_before_refresh.dart';
import '../../domain/usecases/refresh_quota_from_webview.dart';
import '../../domain/usecases/save_manual_refresh_snapshot.dart';

typedef ManualRefreshPageStateProvider = ManualRefreshPageState Function();

class ManualRefreshController extends ChangeNotifier {
  ManualRefreshController({
    required RefreshQuotaFromWebView refreshQuotaFromWebView,
    required SaveManualRefreshSnapshot saveManualRefreshSnapshot,
    required ManualRefreshRepository manualRefreshRepository,
    required ManualRefreshPolicy Function() policyProvider,
    ReloadPageBeforeRefreshUseCase? reloadPageBeforeRefresh,
    ReloadBeforeRefreshPolicy Function()?
    reloadBeforeManualRefreshPolicyProvider,
    ManualRefreshPageStateProvider? currentPageStateProvider,
    Clock clock = const SystemClock(),
  }) : _refreshQuotaFromWebView = refreshQuotaFromWebView,
       _saveManualRefreshSnapshot = saveManualRefreshSnapshot,
       _manualRefreshRepository = manualRefreshRepository,
       _policyProvider = policyProvider,
       _reloadPageBeforeRefresh = reloadPageBeforeRefresh,
       _reloadBeforeManualRefreshPolicyProvider =
           reloadBeforeManualRefreshPolicyProvider,
       _currentPageStateProvider = currentPageStateProvider,
       _clock = clock,
       _lastResult = ManualRefreshResult.idle(clock.now());

  final RefreshQuotaFromWebView _refreshQuotaFromWebView;
  final SaveManualRefreshSnapshot _saveManualRefreshSnapshot;
  final ManualRefreshRepository _manualRefreshRepository;
  final ManualRefreshPolicy Function() _policyProvider;
  final ReloadPageBeforeRefreshUseCase? _reloadPageBeforeRefresh;
  final ReloadBeforeRefreshPolicy Function()?
  _reloadBeforeManualRefreshPolicyProvider;
  final ManualRefreshPageStateProvider? _currentPageStateProvider;
  final Clock _clock;

  ManualRefreshResult _lastResult;
  bool _isRefreshing = false;
  bool _isSaving = false;
  String? _message;
  String? _lastError;

  ManualRefreshResult get lastResult => _lastResult;
  ManualRefreshStatus get status => _lastResult.status;
  bool get isRefreshing => _isRefreshing;
  bool get isSaving => _isSaving;
  bool get isBusy => _isRefreshing || _isSaving || status.isActive;
  String? get message => _message;
  String? get lastError => _lastError;
  String? get lastSavedSnapshotId => _lastResult.savedSnapshotId;
  ManualRefreshPolicy get policy => _policyProvider();
  ReloadBeforeRefreshPolicy get reloadBeforeManualRefreshPolicy =>
      _reloadBeforeManualRefreshPolicyProvider?.call() ??
      ReloadBeforeRefreshPolicy.manualDefault(enabled: false);
  ReloadBeforeRefreshResult? get lastReloadBeforeRefreshResult {
    return _lastResult.reloadBeforeRefreshResult ??
        _reloadPageBeforeRefresh?.lastResult;
  }

  bool get canSaveCandidate {
    return !_isRefreshing &&
        !_isSaving &&
        !_lastResult.isSaved &&
        _lastResult.canSaveWith(policy);
  }

  Future<void> loadLastResult() async {
    try {
      _lastResult =
          await _manualRefreshRepository.getLastResult() ??
          ManualRefreshResult.idle(_clock.now());
      _message = null;
      _lastError = null;
    } on Object catch (error) {
      _lastError = SensitiveDataPolicy.sanitizeLogText(error.toString());
    }
    notifyListeners();
  }

  Future<QuotaSnapshot?> refreshFromCurrentPage(
    ManualRefreshPageState pageState, {
    bool reloadBeforeRefresh = true,
    ReloadCancellationSignal? reloadCancellationSignal,
    ReloadBeforeRefreshResult? completedReloadBeforeRefreshResult,
    ManualRefreshPolicy? policyOverride,
  }) async {
    if (_isRefreshing || _isSaving) {
      return null;
    }

    _isRefreshing = true;
    _message = null;
    _lastError = null;
    notifyListeners();

    try {
      ReloadBeforeRefreshResult? reloadResult =
          completedReloadBeforeRefreshResult;
      var effectivePageState = pageState;
      final reloadPolicy = reloadBeforeManualRefreshPolicy;
      final reloadUseCase = _reloadPageBeforeRefresh;
      if (reloadBeforeRefresh &&
          reloadUseCase != null &&
          reloadPolicy.enabled) {
        reloadResult = await reloadUseCase(
          policy: reloadPolicy,
          isRefreshInProgress: _isSaving,
          cancellationSignal: reloadCancellationSignal,
          onProgress: (progress) {
            _lastResult = _resultForReloadProgress(progress);
            notifyListeners();
          },
        );
        if (!reloadResult.allowsExtraction) {
          final result = await _saveReloadBlockedResult(reloadResult);
          _lastResult = result;
          _message = _messageForResult(result);
          _lastError = result.errors.isEmpty ? null : result.errors.join(' | ');
          return null;
        }
        effectivePageState = _currentPageStateProvider?.call() ?? pageState;
      }

      final result = await _refreshQuotaFromWebView(
        pageState: effectivePageState,
        policy: policyOverride ?? policy,
        reloadBeforeRefreshResult: reloadResult,
        cancellationSignal: reloadCancellationSignal,
        onProgress: (progress) {
          _lastResult = progress;
          notifyListeners();
        },
      );
      _lastResult = result;
      _message = _messageForResult(result);
      _lastError = result.errors.isEmpty ? null : result.errors.join(' | ');
      return result.isSaved ? result.snapshotCandidate : null;
    } on Object catch (error) {
      _lastError = SensitiveDataPolicy.sanitizeLogText(error.toString());
      _message = 'Manual refresh failed.';
      _lastResult = ManualRefreshResult(
        status: ManualRefreshStatus.failed,
        safetyStatus: _lastResult.safetyStatus,
        parserConfidence: _lastResult.parserConfidence,
        extractedPageText: _lastResult.extractedPageText,
        parseResult: _lastResult.parseResult,
        snapshotCandidate: _lastResult.snapshotCandidate,
        redactionSummary: _lastResult.redactionSummary,
        warnings: _lastResult.warnings,
        errors: [_lastError ?? 'Manual refresh failed.'],
        startedAt: _lastResult.startedAt,
        finishedAt: _clock.now(),
        savedSnapshotId: _lastResult.savedSnapshotId,
        reloadBeforeRefreshResult: _lastResult.reloadBeforeRefreshResult,
      );
      return null;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<QuotaSnapshot?> saveSnapshotCandidate() async {
    if (_isRefreshing || _isSaving) {
      return null;
    }

    final current = _lastResult;
    if (!current.canSaveWith(policy)) {
      _message = 'Manual refresh result is not ready to save.';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _lastResult = current.copyWith(status: ManualRefreshStatus.saving);
    _message = null;
    _lastError = null;
    notifyListeners();

    try {
      final result = await _saveManualRefreshSnapshot(current, policy: policy);
      _lastResult = result;
      _message = _messageForResult(result);
      _lastError = result.errors.isEmpty ? null : result.errors.join(' | ');
      return result.isSaved ? result.snapshotCandidate : null;
    } on Object catch (error) {
      _lastError = SensitiveDataPolicy.sanitizeLogText(error.toString());
      _message = 'Unable to save manual refresh snapshot.';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void markSaveCancelled() {
    _message = 'Manual refresh save cancelled.';
    notifyListeners();
  }

  Future<void> clearLastResult() async {
    await _manualRefreshRepository.clearLastResult();
    _lastResult = ManualRefreshResult.idle(_clock.now());
    _message = 'Manual refresh result cleared.';
    _lastError = null;
    notifyListeners();
  }

  String _messageForResult(ManualRefreshResult result) {
    return switch (result.status) {
      ManualRefreshStatus.idle => 'Manual refresh has not run yet.',
      ManualRefreshStatus.checkingPage => 'Checking current WebView page.',
      ManualRefreshStatus.extractingText => 'Extracting visible page text.',
      ManualRefreshStatus.redactingText => 'Redacting extracted text.',
      ManualRefreshStatus.parsing => 'Parsing redacted quota text.',
      ManualRefreshStatus.awaitingUserConfirmation =>
        'Parsed snapshot is ready for review.',
      ManualRefreshStatus.saving => 'Saving parsed snapshot locally.',
      ManualRefreshStatus.saved => 'Manual refresh snapshot saved locally.',
      ManualRefreshStatus.blocked => 'Manual refresh was blocked.',
      ManualRefreshStatus.extractionFailed => 'Manual text extraction failed.',
      ManualRefreshStatus.parseFailed => 'Quota parsing failed.',
      ManualRefreshStatus.lowConfidence =>
        'Low confidence results are not saved.',
      ManualRefreshStatus.failed => 'Manual refresh failed.',
    };
  }

  ManualRefreshResult _resultForReloadProgress(
    ReloadBeforeRefreshResult reloadResult,
  ) {
    return ManualRefreshResult(
      status: reloadResult.status.isTerminal
          ? _statusForReloadResult(reloadResult)
          : ManualRefreshStatus.checkingPage,
      safetyStatus: _lastResult.safetyStatus,
      parserConfidence: _lastResult.parserConfidence,
      extractedPageText: _lastResult.extractedPageText,
      parseResult: _lastResult.parseResult,
      snapshotCandidate: _lastResult.snapshotCandidate,
      redactionSummary: _lastResult.redactionSummary,
      warnings: reloadResult.warnings,
      errors: reloadResult.errors,
      startedAt: reloadResult.startedAt,
      finishedAt: reloadResult.finishedAt,
      savedSnapshotId: _lastResult.savedSnapshotId,
      reloadBeforeRefreshResult: reloadResult,
    );
  }

  Future<ManualRefreshResult> _saveReloadBlockedResult(
    ReloadBeforeRefreshResult reloadResult,
  ) {
    final errors = reloadResult.errors.isEmpty
        ? ['Reload before refresh stopped: ${reloadResult.status.label}.']
        : reloadResult.errors;
    return _manualRefreshRepository.saveLastResult(
      ManualRefreshResult(
        status: _statusForReloadResult(reloadResult),
        safetyStatus: _lastResult.safetyStatus,
        parserConfidence: _lastResult.parserConfidence,
        extractedPageText: null,
        parseResult: null,
        snapshotCandidate: null,
        redactionSummary: null,
        warnings: reloadResult.warnings,
        errors: errors,
        startedAt: reloadResult.startedAt,
        finishedAt: reloadResult.finishedAt ?? _clock.now(),
        savedSnapshotId: null,
        reloadBeforeRefreshResult: reloadResult,
      ),
    );
  }

  ManualRefreshStatus _statusForReloadResult(
    ReloadBeforeRefreshResult reloadResult,
  ) {
    return switch (reloadResult.status) {
      ReloadBeforeRefreshStatus.timeout ||
      ReloadBeforeRefreshStatus.failed ||
      ReloadBeforeRefreshStatus.cancelled => ManualRefreshStatus.failed,
      _ => ManualRefreshStatus.blocked,
    };
  }
}
