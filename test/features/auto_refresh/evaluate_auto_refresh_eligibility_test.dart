import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/auto_refresh/domain/entities/auto_refresh_eligibility.dart';
import 'package:quota_analytics/features/auto_refresh/domain/entities/auto_refresh_policy.dart';
import 'package:quota_analytics/features/auto_refresh/domain/entities/auto_refresh_status.dart';
import 'package:quota_analytics/features/auto_refresh/domain/usecases/evaluate_auto_refresh_eligibility.dart';
import 'package:quota_analytics/features/settings/domain/entities/refresh_interval.dart';

void main() {
  const useCase = EvaluateAutoRefreshEligibility(policy: AutoRefreshPolicy());
  final now = DateTime(2026, 1, 1, 12);

  test('disabled -> skipped', () {
    final decision = useCase(_input(now: now, enabled: false));

    expect(decision.isEligible, isFalse);
    expect(decision.status, AutoRefreshStatus.disabled);
  });

  test('interval off -> skipped', () {
    final decision = useCase(_input(now: now, interval: RefreshInterval.off));

    expect(decision.isEligible, isFalse);
    expect(decision.status, AutoRefreshStatus.disabled);
  });

  test('no WebView -> skippedNoWebView', () {
    final decision = useCase(_input(now: now, hasWebView: false));

    expect(decision.isEligible, isFalse);
    expect(decision.status, AutoRefreshStatus.skippedNoWebView);
  });

  test('page loading -> skippedPageLoading', () {
    final decision = useCase(_input(now: now, isPageLoading: true));

    expect(decision.isEligible, isFalse);
    expect(decision.status, AutoRefreshStatus.skippedPageLoading);
  });

  test('unsafe URL -> skippedUnsafeUrl', () {
    final decision = useCase(_input(now: now, currentUrl: 'http://bad.test'));

    expect(decision.isEligible, isFalse);
    expect(decision.status, AutoRefreshStatus.skippedUnsafeUrl);
  });

  test('interval not reached -> skippedIntervalNotReached', () {
    final decision = useCase(
      _input(
        now: now,
        lastSuccessAt: DateTime(2026, 1, 1, 11, 59),
        interval: RefreshInterval.fiveMinutes,
      ),
    );

    expect(decision.isEligible, isFalse);
    expect(decision.status, AutoRefreshStatus.skippedIntervalNotReached);
    expect(decision.nextEligibleAt, DateTime(2026, 1, 1, 12, 4));
  });

  test('already refreshing -> skipped', () {
    final decision = useCase(_input(now: now, isRefreshInProgress: true));

    expect(decision.isEligible, isFalse);
    expect(decision.status, AutoRefreshStatus.skippedRefreshInProgress);
  });

  test('eligible -> true', () {
    final decision = useCase(_input(now: now));

    expect(decision.isEligible, isTrue);
    expect(decision.status, AutoRefreshStatus.checkingEligibility);
  });
}

AutoRefreshEligibilityInput _input({
  required DateTime now,
  bool enabled = true,
  RefreshInterval interval = RefreshInterval.fiveMinutes,
  bool isForeground = true,
  bool hasWebView = true,
  bool isWebViewReady = true,
  String currentUrl = 'https://chatgpt.com/codex/cloud/settings/analytics',
  bool isPageLoading = false,
  bool isRefreshInProgress = false,
  DateTime? lastSuccessAt,
  DateTime? cooldownUntil,
}) {
  return AutoRefreshEligibilityInput(
    enabled: enabled,
    interval: interval,
    isForeground: isForeground,
    hasWebView: hasWebView,
    isWebViewReady: isWebViewReady,
    currentUrl: currentUrl,
    isPageLoading: isPageLoading,
    isRefreshInProgress: isRefreshInProgress,
    lastSuccessAt: lastSuccessAt,
    cooldownUntil: cooldownUntil,
    now: now,
  );
}
