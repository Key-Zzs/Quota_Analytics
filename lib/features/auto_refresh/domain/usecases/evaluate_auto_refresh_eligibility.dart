import '../../../../core/security/allowed_web_hosts.dart';
import '../entities/auto_refresh_eligibility.dart';
import '../entities/auto_refresh_policy.dart';
import '../entities/auto_refresh_status.dart';

class EvaluateAutoRefreshEligibility {
  const EvaluateAutoRefreshEligibility({required this.policy});

  final AutoRefreshPolicy policy;

  AutoRefreshEligibilityDecision call(AutoRefreshEligibilityInput input) {
    final nextEligibleAt = policy.nextEligibleAt(
      lastSuccessAt: input.lastSuccessAt,
      interval: input.interval,
    );

    if (!input.enabled || input.interval.isOff) {
      return AutoRefreshEligibilityDecision(
        isEligible: false,
        status: AutoRefreshStatus.disabled,
        nextEligibleAt: nextEligibleAt,
        message: 'Foreground auto refresh is disabled.',
      );
    }

    if (!input.isForeground) {
      return AutoRefreshEligibilityDecision(
        isEligible: false,
        status: AutoRefreshStatus.skippedNotForeground,
        nextEligibleAt: nextEligibleAt,
        message: 'App is not in the foreground.',
      );
    }

    if (input.isRefreshInProgress) {
      return AutoRefreshEligibilityDecision(
        isEligible: false,
        status: AutoRefreshStatus.skippedRefreshInProgress,
        nextEligibleAt: nextEligibleAt,
        message: 'A refresh is already in progress.',
      );
    }

    if (policy.isInCooldown(
      now: input.now,
      cooldownUntil: input.cooldownUntil,
    )) {
      return AutoRefreshEligibilityDecision(
        isEligible: false,
        status: AutoRefreshStatus.cooldown,
        nextEligibleAt: input.cooldownUntil,
        message: 'Waiting for the failure cooldown to expire.',
      );
    }

    if (!input.hasWebView || !input.isWebViewReady) {
      return AutoRefreshEligibilityDecision(
        isEligible: false,
        status: AutoRefreshStatus.skippedNoWebView,
        nextEligibleAt: nextEligibleAt,
        message: 'No current WebView page is available.',
      );
    }

    if (input.isPageLoading) {
      return AutoRefreshEligibilityDecision(
        isEligible: false,
        status: AutoRefreshStatus.skippedPageLoading,
        nextEligibleAt: nextEligibleAt,
        message: 'The current WebView page is still loading.',
      );
    }

    final urlDecision = AllowedWebHosts.evaluate(input.currentUrl);
    if (!urlDecision.isAllowed) {
      return AutoRefreshEligibilityDecision(
        isEligible: false,
        status: AutoRefreshStatus.skippedUnsafeUrl,
        nextEligibleAt: nextEligibleAt,
        message: urlDecision.message,
      );
    }

    if (!policy.intervalReached(
      now: input.now,
      lastSuccessAt: input.lastSuccessAt,
      interval: input.interval,
    )) {
      return AutoRefreshEligibilityDecision(
        isEligible: false,
        status: AutoRefreshStatus.skippedIntervalNotReached,
        nextEligibleAt: nextEligibleAt,
        message: 'Refresh interval has not elapsed yet.',
      );
    }

    return AutoRefreshEligibilityDecision(
      isEligible: true,
      status: AutoRefreshStatus.checkingEligibility,
      nextEligibleAt: nextEligibleAt,
      message: 'Foreground auto refresh is eligible.',
    );
  }
}
