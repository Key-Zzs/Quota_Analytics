import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_check_interval.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_refresh_mode.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_refresh_settings.dart';
import 'package:quota_analytics/features/background_refresh/domain/entities/background_stale_threshold.dart';
import 'package:quota_analytics/features/notifications/domain/entities/quota_notification_threshold.dart';

void main() {
  test('default settings are disabled', () {
    final settings = BackgroundRefreshSettings.defaults(DateTime(2026));

    expect(settings.mode, BackgroundRefreshMode.disabled);
    expect(settings.checkInterval, BackgroundCheckInterval.off);
    expect(settings.shouldSchedule, isFalse);
    expect(settings.notificationSettings.localNotificationsEnabled, isFalse);
  });

  test('notifyOnly mode serializes as a stable string', () {
    final settings = BackgroundRefreshSettings.defaults(DateTime(2026))
        .copyWith(
          mode: BackgroundRefreshMode.notifyOnly,
          checkInterval: BackgroundCheckInterval.oneHour,
        );

    expect(settings.toJson()['mode'], 'notifyOnly');
    expect(settings.toJson()['checkInterval'], 'oneHour');
  });

  test('interval and threshold deserialize by string', () {
    final settings = BackgroundRefreshSettings.fromJson(const {
      'mode': 'notifyOnly',
      'checkInterval': 'twoHours',
      'staleDataThreshold': 'sixHours',
    }, fallbackUpdatedAt: DateTime(2026));

    expect(settings.checkInterval, BackgroundCheckInterval.twoHours);
    expect(settings.staleDataThreshold, BackgroundStaleThreshold.sixHours);
  });

  test('JSON round trip keeps notification settings', () {
    final original = BackgroundRefreshSettings.defaults(DateTime(2026))
        .copyWith(
          mode: BackgroundRefreshMode.notifyOnly,
          checkInterval: BackgroundCheckInterval.thirtyMinutes,
          staleDataThreshold: BackgroundStaleThreshold.oneHour,
          notificationSettings:
              BackgroundRefreshSettings.defaults(
                DateTime(2026),
              ).notificationSettings.copyWith(
                localNotificationsEnabled: true,
                lowFiveHourQuotaThreshold: QuotaNotificationThreshold.below20,
                lowWeeklyQuotaThreshold: QuotaNotificationThreshold.below10,
              ),
        );

    final copy = BackgroundRefreshSettings.fromJson(
      original.toJson(),
      fallbackUpdatedAt: DateTime(2027),
    );

    expect(copy.mode, original.mode);
    expect(copy.checkInterval, original.checkInterval);
    expect(copy.staleDataThreshold, original.staleDataThreshold);
    expect(
      copy.notificationSettings.lowFiveHourQuotaThreshold,
      QuotaNotificationThreshold.below20,
    );
    expect(
      copy.notificationSettings.lowWeeklyQuotaThreshold,
      QuotaNotificationThreshold.below10,
    );
  });
}
