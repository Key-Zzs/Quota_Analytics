import '../../../background_refresh/domain/entities/background_refresh_mode.dart';
import '../../../background_refresh/domain/entities/background_stale_threshold.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../entities/notification_candidate.dart';
import '../entities/notification_metadata.dart';
import '../entities/notification_settings.dart';
import '../entities/quota_notification_threshold.dart';

class EvaluateNotificationRules {
  const EvaluateNotificationRules();

  List<NotificationCandidate> call({
    required NotificationSettings settings,
    required BackgroundStaleThreshold staleDataThreshold,
    required BackgroundRefreshMode backgroundRefreshMode,
    required bool backgroundSafeDataSourceAvailable,
    required QuotaSnapshot? latestSnapshot,
    required DateTime? lastRefreshFailedAt,
    required NotificationMetadata metadata,
    required DateTime now,
  }) {
    if (!settings.localNotificationsEnabled) {
      return const [];
    }

    final candidates = <NotificationCandidate>[];

    final staleDuration = staleDataThreshold.duration;
    if (staleDuration != null) {
      final capturedAt = latestSnapshot?.capturedAt;
      if (capturedAt == null || now.difference(capturedAt) >= staleDuration) {
        candidates.add(NotificationCandidate.staleData());
      }
    }

    final snapshot = latestSnapshot;
    if (snapshot != null) {
      _addLowQuotaCandidate(
        candidates: candidates,
        threshold: settings.lowFiveHourQuotaThreshold,
        ratio: snapshot.fiveHourWindow.remainingRatio,
        candidateBuilder: NotificationCandidate.lowFiveHourQuota,
      );
      _addLowQuotaCandidate(
        candidates: candidates,
        threshold: settings.lowWeeklyQuotaThreshold,
        ratio: snapshot.weeklyWindow.remainingRatio,
        candidateBuilder: NotificationCandidate.lowWeeklyQuota,
      );
      final creditsRatio = _creditsRatio(snapshot);
      _addLowQuotaCandidate(
        candidates: candidates,
        threshold: settings.lowCreditsThreshold,
        ratio: creditsRatio,
        candidateBuilder: NotificationCandidate.lowCredits,
      );
    }

    if (settings.refreshFailureReminderEnabled &&
        lastRefreshFailedAt != null) {
      candidates.add(NotificationCandidate.refreshFailed());
    }

    if (backgroundRefreshMode ==
            BackgroundRefreshMode.backgroundSafeDataSourceOnly &&
        !backgroundSafeDataSourceAvailable) {
      candidates.add(NotificationCandidate.backgroundRefreshUnavailable());
    }

    return candidates
        .where(
          (candidate) =>
              candidate.hasSafeContent &&
              !metadata.isCoolingDown(
                type: candidate.type,
                now: now,
                cooldown: settings.cooldown,
              ),
        )
        .toList(growable: false);
  }

  void _addLowQuotaCandidate({
    required List<NotificationCandidate> candidates,
    required QuotaNotificationThreshold threshold,
    required double? ratio,
    required NotificationCandidate Function(QuotaNotificationThreshold)
    candidateBuilder,
  }) {
    final thresholdRatio = threshold.ratio;
    if (thresholdRatio == null || ratio == null) {
      return;
    }
    if (ratio <= thresholdRatio) {
      candidates.add(candidateBuilder(threshold));
    }
  }

  double? _creditsRatio(QuotaSnapshot snapshot) {
    final remaining = snapshot.creditsRemaining;
    final total = snapshot.creditsTotal;
    if (remaining == null || total == null || total <= 0) {
      return null;
    }
    return remaining / total;
  }
}
