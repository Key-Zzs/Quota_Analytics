import '../../../settings/domain/entities/refresh_interval.dart';
import 'auto_refresh_status.dart';

class AutoRefreshEligibilityInput {
  const AutoRefreshEligibilityInput({
    required this.enabled,
    required this.interval,
    required this.isForeground,
    required this.hasWebView,
    required this.isWebViewReady,
    required this.currentUrl,
    required this.isPageLoading,
    required this.isRefreshInProgress,
    required this.lastSuccessAt,
    required this.cooldownUntil,
    required this.now,
  });

  final bool enabled;
  final RefreshInterval interval;
  final bool isForeground;
  final bool hasWebView;
  final bool isWebViewReady;
  final String? currentUrl;
  final bool isPageLoading;
  final bool isRefreshInProgress;
  final DateTime? lastSuccessAt;
  final DateTime? cooldownUntil;
  final DateTime now;
}

class AutoRefreshEligibilityDecision {
  const AutoRefreshEligibilityDecision({
    required this.isEligible,
    required this.status,
    required this.nextEligibleAt,
    required this.message,
  });

  final bool isEligible;
  final AutoRefreshStatus status;
  final DateTime? nextEligibleAt;
  final String message;
}
