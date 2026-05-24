import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/permissions/notification_permission_service.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_check_interval.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_refresh_mode.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_refresh_result.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_refresh_settings.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_refresh_status.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_stale_threshold.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/refresh_failure_metadata.dart';
import 'package:quota_analytics/features/background_refresh/domain/repositories/background_refresh_repository.dart';
import 'package:quota_analytics/features/background_refresh/domain/usecases/evaluate_background_refresh_eligibility.dart';
import 'package:quota_analytics/features/background_refresh/domain/usecases/run_background_refresh_check.dart';
import 'package:quota_analytics/features/notifications/domain/entities/notification_candidate.dart';
import 'package:quota_analytics/features/notifications/domain/entities/notification_metadata.dart';
import 'package:quota_analytics/features/notifications/domain/entities/quota_notification_threshold.dart';
import 'package:quota_analytics/features/notifications/domain/entities/quota_notification_type.dart';
import 'package:quota_analytics/features/notifications/domain/repositories/notification_repository.dart';
import 'package:quota_analytics/features/notifications/domain/usecases/evaluate_notification_rules.dart';
import 'package:quota_analytics/features/notifications/domain/usecases/send_quota_notification.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';
import 'package:quota_analytics/features/quota/data/models/quota_window_model.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_snapshot.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12);

  RunBackgroundRefreshCheck buildUsecase({
    required _FakeBackgroundRepository backgroundRepository,
    required _FakeNotificationRepository notificationRepository,
  }) {
    return RunBackgroundRefreshCheck(
      backgroundRepository: backgroundRepository,
      notificationRepository: notificationRepository,
      evaluateEligibility: const EvaluateBackgroundRefreshEligibility(),
      evaluateNotificationRules: const EvaluateNotificationRules(),
      sendQuotaNotification: SendQuotaNotification(notificationRepository),
    );
  }

  BackgroundRefreshSettings notifySettings() {
    return BackgroundRefreshSettings.defaults(now).copyWith(
      mode: BackgroundRefreshMode.notifyOnly,
      checkInterval: BackgroundCheckInterval.oneHour,
      staleDataThreshold: BackgroundStaleThreshold.oneHour,
      notificationSettings: BackgroundRefreshSettings.defaults(
        now,
      ).notificationSettings.copyWith(localNotificationsEnabled: true),
    );
  }

  test('stale snapshot -> stale notification candidate', () async {
    final background = _FakeBackgroundRepository(
      settings: notifySettings(),
      snapshot: QuotaSnapshotModel.mock(
        capturedAt: now.subtract(const Duration(hours: 2)),
        variant: 1,
      ),
    );
    final notifications = _FakeNotificationRepository();

    final result = await buildUsecase(
      backgroundRepository: background,
      notificationRepository: notifications,
    )(now: now);

    expect(result.status, BackgroundRefreshStatus.staleDataNotificationSent);
    expect(notifications.sent.single.type, QuotaNotificationType.staleData);
  });

  test('low 5-hour remaining -> lowFiveHourQuota notification', () async {
    final settings = notifySettings().copyWith(
      staleDataThreshold: BackgroundStaleThreshold.off,
      notificationSettings: notifySettings().notificationSettings.copyWith(
        lowFiveHourQuotaThreshold: QuotaNotificationThreshold.below20,
      ),
    );
    final background = _FakeBackgroundRepository(
      settings: settings,
      snapshot: _snapshotWithRatios(now, fiveHourRatio: 0.10),
    );
    final notifications = _FakeNotificationRepository();

    await buildUsecase(
      backgroundRepository: background,
      notificationRepository: notifications,
    )(now: now);

    expect(
      notifications.sent.single.type,
      QuotaNotificationType.lowFiveHourQuota,
    );
  });

  test('low weekly remaining -> lowWeeklyQuota notification', () async {
    final settings = notifySettings().copyWith(
      staleDataThreshold: BackgroundStaleThreshold.off,
      notificationSettings: notifySettings().notificationSettings.copyWith(
        lowWeeklyQuotaThreshold: QuotaNotificationThreshold.below10,
      ),
    );
    final background = _FakeBackgroundRepository(
      settings: settings,
      snapshot: _snapshotWithRatios(now, weeklyRatio: 0.05),
    );
    final notifications = _FakeNotificationRepository();

    await buildUsecase(
      backgroundRepository: background,
      notificationRepository: notifications,
    )(now: now);

    expect(
      notifications.sent.single.type,
      QuotaNotificationType.lowWeeklyQuota,
    );
  });

  test('last refresh failed -> refreshFailed notification', () async {
    final background = _FakeBackgroundRepository(
      settings: notifySettings().copyWith(
        staleDataThreshold: BackgroundStaleThreshold.off,
      ),
      snapshot: QuotaSnapshotModel.mock(capturedAt: now, variant: 1),
      failure: RefreshFailureMetadata(
        failed: true,
        occurredAt: now.subtract(const Duration(minutes: 5)),
        statusLabel: 'parse failed',
      ),
    );
    final notifications = _FakeNotificationRepository();

    await buildUsecase(
      backgroundRepository: background,
      notificationRepository: notifications,
    )(now: now);

    expect(notifications.sent.single.type, QuotaNotificationType.refreshFailed);
  });

  test('no issue -> completedNoAction', () async {
    final background = _FakeBackgroundRepository(
      settings: notifySettings().copyWith(
        staleDataThreshold: BackgroundStaleThreshold.off,
      ),
      snapshot: QuotaSnapshotModel.mock(capturedAt: now, variant: 1),
    );
    final notifications = _FakeNotificationRepository();

    final result = await buildUsecase(
      backgroundRepository: background,
      notificationRepository: notifications,
    )(now: now);

    expect(result.status, BackgroundRefreshStatus.completedNoAction);
    expect(notifications.sent, isEmpty);
  });

  test('no safe datasource -> no WebView call, notification only', () async {
    final settings = notifySettings().copyWith(
      mode: BackgroundRefreshMode.backgroundSafeDataSourceOnly,
      staleDataThreshold: BackgroundStaleThreshold.off,
    );
    final background = _FakeBackgroundRepository(
      settings: settings,
      snapshot: QuotaSnapshotModel.mock(capturedAt: now, variant: 1),
      hasSafeDataSource: false,
    );
    final notifications = _FakeNotificationRepository();

    final result = await buildUsecase(
      backgroundRepository: background,
      notificationRepository: notifications,
    )(now: now);

    expect(result.status, BackgroundRefreshStatus.skippedNoSafeDataSource);
    expect(
      notifications.sent.single.type,
      QuotaNotificationType.backgroundRefreshUnavailable,
    );
    expect(background.webViewExtractionCalls, 0);
  });

  test('permission denied evaluates but does not send notification', () async {
    final background = _FakeBackgroundRepository(
      settings: notifySettings(),
      snapshot: QuotaSnapshotModel.mock(
        capturedAt: now.subtract(const Duration(hours: 2)),
        variant: 1,
      ),
    );
    final notifications = _FakeNotificationRepository(
      permissionStatus: NotificationPermissionStatus.denied,
    );

    final result = await buildUsecase(
      backgroundRepository: background,
      notificationRepository: notifications,
    )(now: now);

    expect(result.notificationsSent, 0);
    expect(notifications.sent, isEmpty);
  });
}

QuotaSnapshot _snapshotWithRatios(
  DateTime capturedAt, {
  double fiveHourRatio = 0.80,
  double weeklyRatio = 0.80,
}) {
  final base = QuotaSnapshotModel.mock(capturedAt: capturedAt, variant: 1);
  return QuotaSnapshotModel(
    id: base.id,
    accountLabel: base.accountLabel,
    source: base.source,
    parserConfidence: base.parserConfidence,
    fiveHourWindow: QuotaWindowModel.fromEntity(
      base.fiveHourWindow,
    ).withRatio(fiveHourRatio),
    weeklyWindow: QuotaWindowModel.fromEntity(
      base.weeklyWindow,
    ).withRatio(weeklyRatio),
    creditsRemaining: base.creditsRemaining,
    creditsTotal: base.creditsTotal,
    capturedAt: capturedAt,
    nextSuggestedRefreshAt: base.nextSuggestedRefreshAt,
    rawDebugText: base.rawDebugText,
  );
}

extension on QuotaWindowModel {
  QuotaWindowModel withRatio(double ratio) {
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

class _FakeBackgroundRepository implements BackgroundRefreshRepository {
  _FakeBackgroundRepository({
    required this.settings,
    this.snapshot,
    this.failure = RefreshFailureMetadata.none,
    this.hasSafeDataSource = false,
  });

  BackgroundRefreshSettings settings;
  QuotaSnapshot? snapshot;
  RefreshFailureMetadata failure;
  bool hasSafeDataSource;
  BackgroundRefreshResult? lastResult;
  int webViewExtractionCalls = 0;

  @override
  Future<void> cancel() async {}

  @override
  Future<void> clearLastResult() async {
    lastResult = null;
  }

  @override
  Future<void> clearSettings() async {}

  @override
  Future<bool> hasBackgroundSafeDataSource() async => hasSafeDataSource;

  @override
  Future<BackgroundRefreshResult?> getLastResult() async => lastResult;

  @override
  Future<RefreshFailureMetadata> getLastRefreshFailureMetadata() async =>
      failure;

  @override
  Future<QuotaSnapshot?> getLatestSnapshotForBackground() async => snapshot;

  @override
  Future<BackgroundRefreshSettings> getSettings() async => settings;

  @override
  Future<BackgroundRefreshResult> saveLastResult(
    BackgroundRefreshResult result,
  ) async {
    lastResult = result;
    return result;
  }

  @override
  Future<BackgroundRefreshSettings> saveSettings(
    BackgroundRefreshSettings settings,
  ) async {
    this.settings = settings;
    return settings;
  }

  @override
  Future<void> schedule(BackgroundRefreshSettings settings) async {}
}

class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository({
    this.permissionStatus = NotificationPermissionStatus.granted,
  });

  NotificationPermissionStatus permissionStatus;
  NotificationMetadata metadata = NotificationMetadata.empty();
  final sent = <NotificationCandidate>[];

  @override
  Future<void> clearMetadata() async {
    metadata = NotificationMetadata.empty();
  }

  @override
  Future<NotificationMetadata> getMetadata() async => metadata;

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async =>
      permissionStatus;

  @override
  Future<void> recordSent({
    required QuotaNotificationType type,
    required DateTime sentAt,
  }) async {
    metadata = metadata.markSent(type: type, sentAt: sentAt);
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async =>
      permissionStatus;

  @override
  Future<bool> send(
    NotificationCandidate candidate, {
    required DateTime now,
  }) async {
    if (permissionStatus == NotificationPermissionStatus.denied) {
      return false;
    }
    sent.add(candidate);
    await recordSent(type: candidate.type, sentAt: now);
    return true;
  }
}
