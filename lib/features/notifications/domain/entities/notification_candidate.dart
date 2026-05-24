import 'quota_notification_threshold.dart';
import 'quota_notification_type.dart';

class NotificationCandidate {
  const NotificationCandidate({
    required this.type,
    required this.title,
    required this.body,
    required this.payload,
  });

  factory NotificationCandidate.staleData() {
    return NotificationCandidate(
      type: QuotaNotificationType.staleData,
      title: QuotaNotificationType.staleData.title,
      body: 'Quota data may be stale. Open the app to refresh.',
      payload: QuotaNotificationType.staleData.payload,
    );
  }

  factory NotificationCandidate.lowFiveHourQuota(
    QuotaNotificationThreshold threshold,
  ) {
    return NotificationCandidate(
      type: QuotaNotificationType.lowFiveHourQuota,
      title: QuotaNotificationType.lowFiveHourQuota.title,
      body: '5-hour quota is below ${threshold.percentage ?? 0}%.',
      payload: QuotaNotificationType.lowFiveHourQuota.payload,
    );
  }

  factory NotificationCandidate.lowWeeklyQuota(
    QuotaNotificationThreshold threshold,
  ) {
    return NotificationCandidate(
      type: QuotaNotificationType.lowWeeklyQuota,
      title: QuotaNotificationType.lowWeeklyQuota.title,
      body: 'Weekly quota is below ${threshold.percentage ?? 0}%.',
      payload: QuotaNotificationType.lowWeeklyQuota.payload,
    );
  }

  factory NotificationCandidate.lowCredits(
    QuotaNotificationThreshold threshold,
  ) {
    return NotificationCandidate(
      type: QuotaNotificationType.lowCredits,
      title: QuotaNotificationType.lowCredits.title,
      body: 'Credits are below ${threshold.percentage ?? 0}%.',
      payload: QuotaNotificationType.lowCredits.payload,
    );
  }

  factory NotificationCandidate.refreshFailed() {
    return NotificationCandidate(
      type: QuotaNotificationType.refreshFailed,
      title: QuotaNotificationType.refreshFailed.title,
      body: 'Last refresh failed. Open the app to check.',
      payload: QuotaNotificationType.refreshFailed.payload,
    );
  }

  factory NotificationCandidate.backgroundRefreshUnavailable() {
    return NotificationCandidate(
      type: QuotaNotificationType.backgroundRefreshUnavailable,
      title: QuotaNotificationType.backgroundRefreshUnavailable.title,
      body:
          'Background refresh needs a foreground WebView session. Open the app to refresh.',
      payload: QuotaNotificationType.backgroundRefreshUnavailable.payload,
    );
  }

  final QuotaNotificationType type;
  final String title;
  final String body;
  final String payload;

  int get id => type.notificationId;

  bool get hasSafeContent =>
      isSafeNotificationText(title) && isSafeNotificationText(body);
}

bool isSafeNotificationText(String value) {
  final lower = value.toLowerCase();
  if (RegExp(r'[\w.+-]+@[\w.-]+\.[a-zA-Z]{2,}').hasMatch(value)) {
    return false;
  }
  if (RegExp(r'\bhttps?://').hasMatch(value)) {
    return false;
  }
  if (RegExp(r'\bsk-[A-Za-z0-9_-]{8,}').hasMatch(value)) {
    return false;
  }
  if (RegExp(r'\bBearer\s+[A-Za-z0-9._-]+').hasMatch(value)) {
    return false;
  }
  if (RegExp(r'\b[A-Za-z0-9_-]{32,}\b').hasMatch(value)) {
    return false;
  }
  const blockedTerms = [
    'document.cookie',
    'localstorage',
    'sessionstorage',
    'indexeddb',
    'token=',
    'secret=',
    'access_token',
    'refresh_token',
    'authorization',
    'raw page text',
  ];
  return !blockedTerms.any(lower.contains);
}
