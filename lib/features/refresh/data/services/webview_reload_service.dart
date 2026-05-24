import '../../../../core/security/sensitive_data_policy.dart';
import '../../../auth/presentation/controllers/webview_auth_controller.dart';
import '../../domain/entities/reload_before_refresh_result.dart';
import 'page_load_waiter.dart';

abstract class WebViewReloadService implements PageLoadStateReader {
  bool get hasWebView;
  String get currentUrl;

  Future<void> reload();

  void recordReloadStarted(DateTime startedAt);

  void recordReloadResult(
    ReloadBeforeRefreshResult result, {
    DateTime? cooldownUntil,
  });
}

class WebViewAuthReloadService implements WebViewReloadService {
  const WebViewAuthReloadService({required this.controller});

  final WebViewAuthController controller;

  @override
  bool get hasWebView => controller.isReady;

  @override
  String get currentUrl => controller.currentUrl;

  @override
  bool get isPageLoading => controller.isLoading;

  @override
  DateTime? get lastPageFinishedAt => controller.lastPageFinishedAt;

  @override
  DateTime? get lastWebResourceErrorAt => controller.lastWebResourceErrorAt;

  @override
  String? get lastWebResourceError => controller.lastWebResourceError;

  @override
  void addListener(void Function() listener) {
    controller.addListener(listener);
  }

  @override
  void removeListener(void Function() listener) {
    controller.removeListener(listener);
  }

  @override
  Future<void> reload() {
    return controller.reloadForRefresh();
  }

  @override
  void recordReloadStarted(DateTime startedAt) {
    controller.recordReloadStarted(startedAt);
  }

  @override
  void recordReloadResult(
    ReloadBeforeRefreshResult result, {
    DateTime? cooldownUntil,
  }) {
    controller.recordReloadResult(
      statusLabel: result.status.label,
      startedAt: result.startedAt,
      finishedAt: result.finishedAt,
      duration: result.duration,
      sanitizedUrl: result.sanitizedUrl ?? 'none',
      error: result.errors.isEmpty
          ? null
          : SensitiveDataPolicy.sanitizeLogText(result.errors.join(' | ')),
      cooldownUntil: cooldownUntil,
    );
  }
}
