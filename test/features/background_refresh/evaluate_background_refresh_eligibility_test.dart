import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/permissions/notification_permission_service.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_check_interval.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_refresh_eligibility.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_refresh_mode.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_refresh_result.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_refresh_settings.dart';
import 'package:quota_analytics/features/background_refresh/domain/usecases/evaluate_background_refresh_eligibility.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12);
  const usecase = EvaluateBackgroundRefreshEligibility();

  BackgroundRefreshSettings enabled(BackgroundRefreshMode mode) {
    return BackgroundRefreshSettings.defaults(now).copyWith(
      mode: mode,
      checkInterval: BackgroundCheckInterval.oneHour,
    );
  }

  test('disabled -> skippedDisabled', () {
    final result = usecase(
      settings: BackgroundRefreshSettings.defaults(now),
      latestSnapshot: null,
      lastSuccessfulRefreshAt: null,
      lastFailedRefreshAt: null,
      now: now,
      appInForeground: false,
      backgroundSafeDataSourceAvailable: false,
      notificationPermissionStatus: NotificationPermissionStatus.unknown,
    );

    expect(result.status, BackgroundRefreshEligibilityStatus.skippedDisabled);
    expect(result.shouldRunLocalCheck, isFalse);
  });

  test('notifyOnly -> allowed notifyOnly', () {
    final result = usecase(
      settings: enabled(BackgroundRefreshMode.notifyOnly),
      latestSnapshot: QuotaSnapshotModel.mock(capturedAt: now, variant: 1),
      lastSuccessfulRefreshAt: now,
      lastFailedRefreshAt: null,
      now: now,
      appInForeground: false,
      backgroundSafeDataSourceAvailable: false,
      notificationPermissionStatus: NotificationPermissionStatus.granted,
    );

    expect(result.status, BackgroundRefreshEligibilityStatus.notifyOnly);
    expect(result.allowed, isTrue);
    expect(result.notifyOnly, isTrue);
  });

  test('backgroundSafeDataSourceOnly without datasource falls back notifyOnly', () {
    final result = usecase(
      settings: enabled(BackgroundRefreshMode.backgroundSafeDataSourceOnly),
      latestSnapshot: null,
      lastSuccessfulRefreshAt: null,
      lastFailedRefreshAt: null,
      now: now,
      appInForeground: false,
      backgroundSafeDataSourceAvailable: false,
      notificationPermissionStatus: NotificationPermissionStatus.granted,
    );

    expect(
      result.status,
      BackgroundRefreshEligibilityStatus.skippedNoBackgroundSafeDataSource,
    );
    expect(result.notifyOnly, isTrue);
    expect(result.warnings.single, contains('falling back to notify-only'));
  });

  test('cooldown active -> skippedCooldown', () {
    final result = usecase(
      settings: enabled(BackgroundRefreshMode.notifyOnly),
      latestSnapshot: null,
      lastSuccessfulRefreshAt: null,
      lastFailedRefreshAt: null,
      now: now,
      appInForeground: false,
      backgroundSafeDataSourceAvailable: false,
      notificationPermissionStatus: NotificationPermissionStatus.granted,
      lastRunResult:
          BackgroundRefreshResult.running(now.subtract(const Duration(minutes: 5))),
    );

    expect(result.status, BackgroundRefreshEligibilityStatus.skippedCooldown);
    expect(result.remainingCooldown, const Duration(minutes: 10));
  });

  test('notification permission denied still evaluates local check', () {
    final result = usecase(
      settings: enabled(BackgroundRefreshMode.notifyOnly),
      latestSnapshot: null,
      lastSuccessfulRefreshAt: null,
      lastFailedRefreshAt: null,
      now: now,
      appInForeground: false,
      backgroundSafeDataSourceAvailable: false,
      notificationPermissionStatus: NotificationPermissionStatus.denied,
    );

    expect(result.shouldRunLocalCheck, isTrue);
    expect(result.warnings.single, contains('permission is denied'));
  });

  test('no latest snapshot still allows notify-only local check', () {
    final result = usecase(
      settings: enabled(BackgroundRefreshMode.notifyOnly),
      latestSnapshot: null,
      lastSuccessfulRefreshAt: null,
      lastFailedRefreshAt: null,
      now: now,
      appInForeground: false,
      backgroundSafeDataSourceAvailable: false,
      notificationPermissionStatus: NotificationPermissionStatus.granted,
    );

    expect(result.shouldRunLocalCheck, isTrue);
  });
}
