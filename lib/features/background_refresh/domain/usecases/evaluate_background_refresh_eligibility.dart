import '../../../../core/permissions/notification_permission_service.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../entities/background_refresh_eligibility.dart';
import '../entities/background_refresh_mode.dart';
import '../entities/background_refresh_result.dart';
import '../entities/background_refresh_settings.dart';

class EvaluateBackgroundRefreshEligibility {
  const EvaluateBackgroundRefreshEligibility();

  BackgroundRefreshEligibility call({
    required BackgroundRefreshSettings settings,
    required QuotaSnapshot? latestSnapshot,
    required DateTime? lastSuccessfulRefreshAt,
    required DateTime? lastFailedRefreshAt,
    required DateTime now,
    required bool appInForeground,
    required bool backgroundSafeDataSourceAvailable,
    required NotificationPermissionStatus notificationPermissionStatus,
    BackgroundRefreshResult? lastRunResult,
    bool systemConstraintsSatisfied = true,
  }) {
    final warnings = <String>[];

    if (settings.mode == BackgroundRefreshMode.disabled ||
        settings.checkInterval.isOff) {
      return BackgroundRefreshEligibility(
        status: BackgroundRefreshEligibilityStatus.skippedDisabled,
        evaluatedAt: now,
        allowed: false,
        notifyOnly: false,
        warnings: warnings,
        errors: const [],
      );
    }

    if (!systemConstraintsSatisfied) {
      return BackgroundRefreshEligibility(
        status:
            BackgroundRefreshEligibilityStatus
                .skippedBatteryOrSystemConstraint,
        evaluatedAt: now,
        allowed: false,
        notifyOnly: false,
        warnings: warnings,
        errors: const [],
      );
    }

    final lastRunAt = lastRunResult?.startedAt;
    if (lastRunAt != null &&
        now.difference(lastRunAt) < settings.minimumRunSpacing) {
      return BackgroundRefreshEligibility(
        status: BackgroundRefreshEligibilityStatus.skippedCooldown,
        evaluatedAt: now,
        allowed: false,
        notifyOnly: false,
        warnings: warnings,
        errors: const [],
        remainingCooldown: settings.minimumRunSpacing - now.difference(lastRunAt),
      );
    }

    if (notificationPermissionStatus == NotificationPermissionStatus.denied) {
      warnings.add('Notification permission is denied; local check can still run.');
    } else if (notificationPermissionStatus ==
        NotificationPermissionStatus.unknown) {
      warnings.add('Notification permission status is unknown.');
    }

    if (settings.mode == BackgroundRefreshMode.notifyOnly) {
      return BackgroundRefreshEligibility(
        status: BackgroundRefreshEligibilityStatus.notifyOnly,
        evaluatedAt: now,
        allowed: true,
        notifyOnly: true,
        warnings: warnings,
        errors: const [],
      );
    }

    if (settings.mode == BackgroundRefreshMode.backgroundSafeDataSourceOnly &&
        !backgroundSafeDataSourceAvailable) {
      warnings.add(
        'No background-safe data source is available; falling back to notify-only.',
      );
      return BackgroundRefreshEligibility(
        status:
            BackgroundRefreshEligibilityStatus
                .skippedNoBackgroundSafeDataSource,
        evaluatedAt: now,
        allowed: true,
        notifyOnly: true,
        warnings: warnings,
        errors: const [],
      );
    }

    return BackgroundRefreshEligibility(
      status: BackgroundRefreshEligibilityStatus.allowed,
      evaluatedAt: now,
      allowed: true,
      notifyOnly: false,
      warnings: warnings,
      errors: const [],
    );
  }
}
