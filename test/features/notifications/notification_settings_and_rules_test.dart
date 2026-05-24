import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_refresh_mode.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_stale_threshold.dart';
import 'package:quota_analytics/features/notifications/domain/entities/notification_candidate.dart';
import 'package:quota_analytics/features/notifications/domain/entities/notification_metadata.dart';
import 'package:quota_analytics/features/notifications/domain/entities/notification_settings.dart';
import 'package:quota_analytics/features/notifications/domain/entities/quota_notification_threshold.dart';
import 'package:quota_analytics/features/notifications/domain/entities/quota_notification_type.dart';
import 'package:quota_analytics/features/notifications/domain/usecases/evaluate_notification_rules.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';
import 'package:quota_analytics/features/quota/data/models/quota_window_model.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12);
  const evaluator = EvaluateNotificationRules();

  test('NotificationSettings default disabled', () {
    final settings = NotificationSettings.defaults();

    expect(settings.localNotificationsEnabled, isFalse);
    expect(settings.lowFiveHourQuotaThreshold, QuotaNotificationThreshold.off);
    expect(settings.lowWeeklyQuotaThreshold, QuotaNotificationThreshold.off);
  });

  test('threshold values are correct', () {
    expect(QuotaNotificationThreshold.below20.ratio, 0.20);
    expect(QuotaNotificationThreshold.below10.percentage, 10);
    expect(QuotaNotificationThreshold.below5.label, 'below 5%');
  });

  test('NotificationSettings JSON round trip', () {
    final original = NotificationSettings.defaults().copyWith(
      localNotificationsEnabled: true,
      lowFiveHourQuotaThreshold: QuotaNotificationThreshold.below20,
      refreshFailureReminderEnabled: false,
    );
    final copy = NotificationSettings.fromJson(original.toJson());

    expect(copy.localNotificationsEnabled, isTrue);
    expect(copy.lowFiveHourQuotaThreshold, QuotaNotificationThreshold.below20);
    expect(copy.refreshFailureReminderEnabled, isFalse);
  });

  test('reminders disabled -> no candidates', () {
    final candidates = evaluator(
      settings: NotificationSettings.defaults(),
      staleDataThreshold: BackgroundStaleThreshold.oneHour,
      backgroundRefreshMode: BackgroundRefreshMode.notifyOnly,
      backgroundSafeDataSourceAvailable: false,
      latestSnapshot: QuotaSnapshotModel.mock(
        capturedAt: now.subtract(const Duration(hours: 2)),
        variant: 1,
      ),
      lastRefreshFailedAt: now,
      metadata: NotificationMetadata.empty(),
      now: now,
    );

    expect(candidates, isEmpty);
  });

  test('stale threshold works', () {
    final candidates = evaluator(
      settings: NotificationSettings.defaults().copyWith(
        localNotificationsEnabled: true,
      ),
      staleDataThreshold: BackgroundStaleThreshold.oneHour,
      backgroundRefreshMode: BackgroundRefreshMode.notifyOnly,
      backgroundSafeDataSourceAvailable: false,
      latestSnapshot: QuotaSnapshotModel.mock(
        capturedAt: now.subtract(const Duration(hours: 2)),
        variant: 1,
      ),
      lastRefreshFailedAt: null,
      metadata: NotificationMetadata.empty(),
      now: now,
    );

    expect(candidates.single.type, QuotaNotificationType.staleData);
  });

  test('low quota threshold works', () {
    final snapshot = QuotaSnapshotModel.mock(capturedAt: now, variant: 1);
    final candidates = evaluator(
      settings: NotificationSettings.defaults().copyWith(
        localNotificationsEnabled: true,
        lowFiveHourQuotaThreshold: QuotaNotificationThreshold.below20,
      ),
      staleDataThreshold: BackgroundStaleThreshold.off,
      backgroundRefreshMode: BackgroundRefreshMode.notifyOnly,
      backgroundSafeDataSourceAvailable: false,
      latestSnapshot: snapshot.copyWithFiveHourRatio(0.10),
      lastRefreshFailedAt: null,
      metadata: NotificationMetadata.empty(),
      now: now,
    );

    expect(candidates.single.type, QuotaNotificationType.lowFiveHourQuota);
  });

  test('cooldown prevents duplicate', () {
    final metadata = NotificationMetadata.empty().markSent(
      type: QuotaNotificationType.staleData,
      sentAt: now.subtract(const Duration(minutes: 10)),
    );
    final candidates = evaluator(
      settings: NotificationSettings.defaults().copyWith(
        localNotificationsEnabled: true,
      ),
      staleDataThreshold: BackgroundStaleThreshold.oneHour,
      backgroundRefreshMode: BackgroundRefreshMode.notifyOnly,
      backgroundSafeDataSourceAvailable: false,
      latestSnapshot: QuotaSnapshotModel.mock(
        capturedAt: now.subtract(const Duration(hours: 2)),
        variant: 1,
      ),
      lastRefreshFailedAt: null,
      metadata: metadata,
      now: now,
    );

    expect(candidates, isEmpty);
  });

  test('notification content is safe', () {
    expect(NotificationCandidate.staleData().hasSafeContent, isTrue);
    expect(NotificationCandidate.refreshFailed().hasSafeContent, isTrue);
    expect(isSafeNotificationText('token=abc123'), isFalse);
    expect(isSafeNotificationText('person@example.com'), isFalse);
    expect(
      isSafeNotificationText('https://example.com/?token=secret'),
      isFalse,
    );
  });
}

extension on QuotaSnapshotModel {
  QuotaSnapshotModel copyWithFiveHourRatio(double ratio) {
    return QuotaSnapshotModel(
      id: id,
      accountLabel: accountLabel,
      source: source,
      parserConfidence: parserConfidence,
      fiveHourWindow: QuotaWindowModel.fromEntity(
        fiveHourWindow,
      ).copyWithRatio(ratio),
      weeklyWindow: weeklyWindow,
      creditsRemaining: creditsRemaining,
      creditsTotal: creditsTotal,
      capturedAt: capturedAt,
      nextSuggestedRefreshAt: nextSuggestedRefreshAt,
      rawDebugText: rawDebugText,
    );
  }
}

extension on QuotaWindowModel {
  QuotaWindowModel copyWithRatio(double ratio) {
    return QuotaWindowModel(
      label: label,
      used: used,
      limit: limit,
      remaining: remaining,
      remainingRatio: ratio,
      resetAt: resetAt,
      status: status,
    );
  }
}
