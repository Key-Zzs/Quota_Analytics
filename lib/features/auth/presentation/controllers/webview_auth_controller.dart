import 'package:flutter/foundation.dart';

import '../../../../core/security/sensitive_data_policy.dart';
import '../../../../core/time/clock.dart';
import '../../domain/entities/web_auth_config.dart';
import '../../domain/entities/web_auth_navigation_error.dart';
import '../../domain/entities/web_auth_status.dart';
import '../../domain/entities/webview_clear_result.dart';
import '../../domain/repositories/web_auth_repository.dart';

class WebViewAuthController extends ChangeNotifier {
  WebViewAuthController({
    this.config = const WebAuthConfig(),
    WebAuthRepository? repository,
    Clock clock = const SystemClock(),
  }) : _repository = repository,
       _clock = clock;

  final WebAuthConfig config;
  final Clock _clock;
  WebAuthRepository? _repository;

  WebAuthStatus _authStatus = WebAuthStatus.unknown;
  String _currentUrl = 'none';
  String _pageTitle = 'none';
  int _loadingProgress = 0;
  bool _isLoading = false;
  bool _canGoBack = false;
  bool _canGoForward = false;
  DateTime? _lastNavigationTime;
  DateTime? _lastPageStartedAt;
  DateTime? _lastPageFinishedAt;
  DateTime? _lastDataClearTime;
  String? _lastError;
  DateTime? _lastWebResourceErrorAt;
  String? _lastWebResourceError;
  String? _message;
  WebViewClearResult? _lastClearResult;
  DateTime? _lastReloadAt;
  DateTime? _lastReloadStartedAt;
  DateTime? _lastReloadFinishedAt;
  Duration? _lastReloadDuration;
  String _lastReloadStatus = 'idle';
  String? _lastReloadError;
  String _lastReloadSanitizedUrl = 'none';
  DateTime? _reloadCooldownUntil;

  WebAuthStatus get authStatus => _authStatus;
  String get currentUrl => _currentUrl;
  String get pageTitle => _pageTitle;
  int get loadingProgress => _loadingProgress;
  bool get isLoading => _isLoading;
  bool get canGoBack => _canGoBack;
  bool get canGoForward => _canGoForward;
  DateTime? get lastNavigationTime => _lastNavigationTime;
  DateTime? get lastPageStartedAt => _lastPageStartedAt;
  DateTime? get lastPageFinishedAt => _lastPageFinishedAt;
  DateTime? get lastDataClearTime => _lastDataClearTime;
  String? get lastError => _lastError;
  DateTime? get lastWebResourceErrorAt => _lastWebResourceErrorAt;
  String? get lastWebResourceError => _lastWebResourceError;
  String? get message => _message;
  WebViewClearResult? get lastClearResult => _lastClearResult;
  DateTime? get lastReloadAt => _lastReloadAt;
  DateTime? get lastReloadStartedAt => _lastReloadStartedAt;
  DateTime? get lastReloadFinishedAt => _lastReloadFinishedAt;
  Duration? get lastReloadDuration => _lastReloadDuration;
  String get lastReloadStatus => _lastReloadStatus;
  String? get lastReloadError => _lastReloadError;
  String get lastReloadSanitizedUrl => _lastReloadSanitizedUrl;
  DateTime? get reloadCooldownUntil => _reloadCooldownUntil;
  bool get isReady => _repository != null;

  void attachRepository(WebAuthRepository repository) {
    _repository = repository;
    notifyListeners();
  }

  Future<void> openLoginPage() {
    return _load(config.loginUri);
  }

  Future<void> openUsagePage() {
    return _load(config.usageUri);
  }

  Future<void> reload() {
    return _runWithRepository((repository) async {
      await repository.reload();
      await _refreshNavigationAvailability(notify: false);
    });
  }

  Future<void> reloadForRefresh() {
    return _runWithRepositoryThrowing((repository) async {
      _lastError = null;
      _message = null;
      notifyListeners();
      await repository.reload();
      await _refreshNavigationAvailability(notify: false);
    });
  }

  Future<void> goBack() {
    return _runWithRepository((repository) async {
      await repository.goBack();
      await _refreshNavigationAvailability(notify: false);
    });
  }

  Future<void> goForward() {
    return _runWithRepository((repository) async {
      await repository.goForward();
      await _refreshNavigationAvailability(notify: false);
    });
  }

  Future<void> clearWebViewData() {
    return _runWithRepository((repository) async {
      final result = await repository.clearWebViewData();
      _lastClearResult = result;
      _lastDataClearTime = _clock.now();
      _message = result.summary;
      _lastError = null;
      await _refreshNavigationAvailability(notify: false);
    });
  }

  void onPageStarted(String rawUrl) {
    _currentUrl = SensitiveDataPolicy.sanitizeUrlForDisplay(rawUrl);
    _authStatus = config.inferStatusFromNavigation(
      rawUrl: rawUrl,
      title: _pageTitle,
    );
    _isLoading = true;
    _loadingProgress = 0;
    final now = _clock.now();
    _lastNavigationTime = now;
    _lastPageStartedAt = now;
    _lastError = null;
    _lastWebResourceError = null;
    _lastWebResourceErrorAt = null;
    _message = null;
    notifyListeners();
  }

  void onProgress(int progress) {
    _loadingProgress = progress.clamp(0, 100);
    if (_loadingProgress < 100) {
      _isLoading = true;
    }
    notifyListeners();
  }

  Future<void> onPageFinished(String rawUrl) async {
    final repository = _repository;
    final title = repository == null ? null : await repository.pageTitle();
    _currentUrl = SensitiveDataPolicy.sanitizeUrlForDisplay(rawUrl);
    _pageTitle = _sanitizeTitle(title);
    _authStatus = config.inferStatusFromNavigation(
      rawUrl: rawUrl,
      title: title,
    );
    _isLoading = false;
    _loadingProgress = 100;
    final now = _clock.now();
    _lastNavigationTime = now;
    _lastPageFinishedAt = now;
    await _refreshNavigationAvailability(notify: false);
    notifyListeners();
  }

  void onUrlChanged(String rawUrl) {
    _currentUrl = SensitiveDataPolicy.sanitizeUrlForDisplay(rawUrl);
    _authStatus = config.inferStatusFromNavigation(
      rawUrl: rawUrl,
      title: _pageTitle,
    );
    _lastNavigationTime = _clock.now();
    notifyListeners();
  }

  void onWebResourceError(WebAuthNavigationError error) {
    _authStatus = WebAuthStatus.error;
    _isLoading = false;
    final safeMessage = error.safeMessage;
    _lastError = safeMessage;
    _lastWebResourceError = safeMessage;
    _lastWebResourceErrorAt = _clock.now();
    _message = null;
    notifyListeners();
  }

  void onNavigationBlocked(String rawUrl, String reason) {
    _currentUrl = SensitiveDataPolicy.sanitizeUrlForDisplay(rawUrl);
    _authStatus = WebAuthStatus.blocked;
    _isLoading = false;
    _lastError = SensitiveDataPolicy.sanitizeLogText(reason);
    _lastNavigationTime = _clock.now();
    notifyListeners();
  }

  void recordReloadStarted(DateTime startedAt) {
    _lastReloadAt = startedAt;
    _lastReloadStartedAt = startedAt;
    _lastReloadFinishedAt = null;
    _lastReloadDuration = null;
    _lastReloadStatus = 'reloading';
    _lastReloadError = null;
    _lastReloadSanitizedUrl = _currentUrl;
    notifyListeners();
  }

  void recordReloadResult({
    required String statusLabel,
    required DateTime startedAt,
    required DateTime? finishedAt,
    required Duration? duration,
    required String sanitizedUrl,
    required String? error,
    required DateTime? cooldownUntil,
  }) {
    _lastReloadAt = startedAt;
    _lastReloadStartedAt = startedAt;
    _lastReloadFinishedAt = finishedAt;
    _lastReloadDuration = duration;
    _lastReloadStatus = SensitiveDataPolicy.sanitizeLogText(statusLabel);
    _lastReloadError = error == null
        ? null
        : SensitiveDataPolicy.sanitizeLogText(error);
    _lastReloadSanitizedUrl = sanitizedUrl == 'none'
        ? 'none'
        : SensitiveDataPolicy.sanitizeUrlForDisplay(sanitizedUrl);
    _reloadCooldownUntil = cooldownUntil;
    notifyListeners();
  }

  Future<void> _load(Uri uri) {
    return _runWithRepository((repository) async {
      final rawUrl = uri.toString();
      _currentUrl = SensitiveDataPolicy.sanitizeUrlForDisplay(rawUrl);
      _authStatus = config.inferStatusFromNavigation(rawUrl: rawUrl);
      _isLoading = true;
      _loadingProgress = 0;
      _lastNavigationTime = _clock.now();
      _lastError = null;
      _message = null;
      notifyListeners();
      await repository.load(uri);
      await _refreshNavigationAvailability(notify: false);
    });
  }

  Future<void> _runWithRepository(
    Future<void> Function(WebAuthRepository repository) action,
  ) async {
    final repository = _repository;
    if (repository == null) {
      _authStatus = WebAuthStatus.error;
      _lastError = 'WebView controller is not ready.';
      notifyListeners();
      return;
    }

    try {
      await action(repository);
    } catch (error) {
      _authStatus = WebAuthStatus.error;
      _isLoading = false;
      _lastError = SensitiveDataPolicy.sanitizeLogText(error.toString());
    }
    notifyListeners();
  }

  Future<void> _runWithRepositoryThrowing(
    Future<void> Function(WebAuthRepository repository) action,
  ) async {
    final repository = _repository;
    if (repository == null) {
      _authStatus = WebAuthStatus.error;
      _lastError = 'WebView controller is not ready.';
      notifyListeners();
      throw StateError(_lastError!);
    }

    try {
      await action(repository);
    } catch (error) {
      final safeError = SensitiveDataPolicy.sanitizeLogText(error.toString());
      _authStatus = WebAuthStatus.error;
      _isLoading = false;
      _lastError = safeError;
      notifyListeners();
      throw StateError(safeError);
    }
    notifyListeners();
  }

  Future<void> _refreshNavigationAvailability({required bool notify}) async {
    final repository = _repository;
    if (repository == null) {
      _canGoBack = false;
      _canGoForward = false;
      return;
    }

    try {
      _canGoBack = await repository.canGoBack();
      _canGoForward = await repository.canGoForward();
    } catch (error) {
      _lastError = SensitiveDataPolicy.sanitizeLogText(error.toString());
    }

    if (notify) {
      notifyListeners();
    }
  }

  String _sanitizeTitle(String? title) {
    final value = title?.trim();
    if (value == null || value.isEmpty) {
      return 'none';
    }
    return SensitiveDataPolicy.sanitizeLogText(value);
  }
}
