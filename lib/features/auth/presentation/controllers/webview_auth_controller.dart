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
  DateTime? _lastDataClearTime;
  String? _lastError;
  String? _message;
  WebViewClearResult? _lastClearResult;

  WebAuthStatus get authStatus => _authStatus;
  String get currentUrl => _currentUrl;
  String get pageTitle => _pageTitle;
  int get loadingProgress => _loadingProgress;
  bool get isLoading => _isLoading;
  bool get canGoBack => _canGoBack;
  bool get canGoForward => _canGoForward;
  DateTime? get lastNavigationTime => _lastNavigationTime;
  DateTime? get lastDataClearTime => _lastDataClearTime;
  String? get lastError => _lastError;
  String? get message => _message;
  WebViewClearResult? get lastClearResult => _lastClearResult;
  bool get isReady => _repository != null;

  void attachRepository(WebAuthRepository repository) {
    _repository = repository;
    notifyListeners();
  }

  Future<void> openLoginPage() {
    return _load(config.loginUri);
  }

  Future<void> openUsagePagePlaceholder() {
    return _load(config.usageUriPlaceholder);
  }

  Future<void> reload() {
    return _runWithRepository((repository) async {
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
    _lastNavigationTime = _clock.now();
    _lastError = null;
    _message = null;
    notifyListeners();
  }

  void onProgress(int progress) {
    _loadingProgress = progress.clamp(0, 100);
    _isLoading = _loadingProgress < 100;
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
    _lastNavigationTime = _clock.now();
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
    _lastError = error.safeMessage;
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
