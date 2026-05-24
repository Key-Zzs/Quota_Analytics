import '../../../notifications/domain/entities/notification_candidate.dart';
import '../../../notifications/domain/repositories/notification_repository.dart';
import '../../../notifications/domain/usecases/evaluate_notification_rules.dart';
import '../../../notifications/domain/usecases/send_quota_notification.dart';
import '../entities/background_refresh_eligibility.dart';
import '../entities/background_refresh_result.dart';
import '../entities/background_refresh_status.dart';
import '../repositories/background_refresh_repository.dart';
import 'evaluate_background_refresh_eligibility.dart';

class RunBackgroundRefreshCheck {
  const RunBackgroundRefreshCheck({
    required this.backgroundRepository,
    required this.notificationRepository,
    required this.evaluateEligibility,
    required this.evaluateNotificationRules,
    required this.sendQuotaNotification,
  });

  final BackgroundRefreshRepository backgroundRepository;
  final NotificationRepository notificationRepository;
  final EvaluateBackgroundRefreshEligibility evaluateEligibility;
  final EvaluateNotificationRules evaluateNotificationRules;
  final SendQuotaNotification sendQuotaNotification;

  Future<BackgroundRefreshResult> call({required DateTime now}) async {
    final running = BackgroundRefreshResult.running(now);

    try {
      final settings = await backgroundRepository.getSettings();
      final latestSnapshot = await backgroundRepository
          .getLatestSnapshotForBackground();
      final refreshFailure = await backgroundRepository
          .getLastRefreshFailureMetadata();
      final lastRun = await backgroundRepository.getLastResult();
      final permissionStatus = await notificationRepository
          .getPermissionStatus();
      final hasBackgroundSafeDataSource = await backgroundRepository
          .hasBackgroundSafeDataSource();

      final eligibility = evaluateEligibility(
        settings: settings,
        latestSnapshot: latestSnapshot,
        lastSuccessfulRefreshAt: latestSnapshot?.capturedAt,
        lastFailedRefreshAt: refreshFailure.occurredAt,
        now: now,
        appInForeground: false,
        backgroundSafeDataSourceAvailable: hasBackgroundSafeDataSource,
        notificationPermissionStatus: permissionStatus,
        lastRunResult: lastRun,
      );

      if (!eligibility.shouldRunLocalCheck) {
        final result = running.finish(
          status: _statusForSkippedEligibility(eligibility),
          finishedAt: now,
          warnings: eligibility.warnings,
          errors: eligibility.errors,
        );
        return backgroundRepository.saveLastResult(result);
      }

      final metadata = await notificationRepository.getMetadata();
      final candidates = evaluateNotificationRules(
        settings: settings.notificationSettings,
        staleDataThreshold: settings.staleDataThreshold,
        backgroundRefreshMode: settings.mode,
        backgroundSafeDataSourceAvailable: hasBackgroundSafeDataSource,
        latestSnapshot: latestSnapshot,
        lastRefreshFailedAt: refreshFailure.failed
            ? refreshFailure.occurredAt
            : null,
        metadata: metadata,
        now: now,
      );

      var sent = 0;
      final sentCandidates = <NotificationCandidate>[];
      for (final candidate in candidates) {
        final didSend = await sendQuotaNotification(candidate, now: now);
        if (didSend) {
          sent += 1;
          sentCandidates.add(candidate);
        }
      }

      final status = _statusForNotificationOutcome(
        eligibility: eligibility,
        sentCandidates: sentCandidates,
      );
      final result = running.finish(
        status: status,
        finishedAt: now,
        warnings: eligibility.warnings,
        errors: eligibility.errors,
        notificationsSent: sent,
        safeDataSourceUsed: hasBackgroundSafeDataSource ? 'future-safe' : null,
      );
      return backgroundRepository.saveLastResult(result);
    } on Object catch (error) {
      final result = running.finish(
        status: BackgroundRefreshStatus.failed,
        finishedAt: now,
        errors: ['Background refresh check failed: $error'],
      );
      return backgroundRepository.saveLastResult(result);
    }
  }

  BackgroundRefreshStatus _statusForSkippedEligibility(
    BackgroundRefreshEligibility eligibility,
  ) {
    return switch (eligibility.status) {
      BackgroundRefreshEligibilityStatus.skippedDisabled =>
        BackgroundRefreshStatus.disabled,
      BackgroundRefreshEligibilityStatus.skippedCooldown =>
        BackgroundRefreshStatus.skippedCooldown,
      BackgroundRefreshEligibilityStatus.skippedNoBackgroundSafeDataSource =>
        BackgroundRefreshStatus.skippedNoSafeDataSource,
      BackgroundRefreshEligibilityStatus.skippedBatteryOrSystemConstraint =>
        BackgroundRefreshStatus.skippedCooldown,
      BackgroundRefreshEligibilityStatus.failed =>
        BackgroundRefreshStatus.failed,
      _ => BackgroundRefreshStatus.completedNoAction,
    };
  }

  BackgroundRefreshStatus _statusForNotificationOutcome({
    required BackgroundRefreshEligibility eligibility,
    required List<NotificationCandidate> sentCandidates,
  }) {
    if (sentCandidates.any((candidate) => candidate.type.name == 'staleData')) {
      return BackgroundRefreshStatus.staleDataNotificationSent;
    }
    if (sentCandidates.any(
      (candidate) => candidate.type.name.startsWith('low'),
    )) {
      return BackgroundRefreshStatus.lowQuotaNotificationSent;
    }
    if (sentCandidates.any(
      (candidate) => candidate.type.name == 'refreshFailed',
    )) {
      return BackgroundRefreshStatus.refreshFailureNotificationSent;
    }
    if (eligibility.status ==
        BackgroundRefreshEligibilityStatus.skippedNoBackgroundSafeDataSource) {
      return BackgroundRefreshStatus.skippedNoSafeDataSource;
    }
    return BackgroundRefreshStatus.completedNoAction;
  }
}
