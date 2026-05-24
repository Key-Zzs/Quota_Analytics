enum QuotaNotificationType {
  staleData,
  lowFiveHourQuota,
  lowWeeklyQuota,
  lowCredits,
  refreshFailed,
  backgroundRefreshUnavailable;

  String get storageKey => name;

  int get notificationId {
    return switch (this) {
      QuotaNotificationType.staleData => 8101,
      QuotaNotificationType.lowFiveHourQuota => 8102,
      QuotaNotificationType.lowWeeklyQuota => 8103,
      QuotaNotificationType.lowCredits => 8104,
      QuotaNotificationType.refreshFailed => 8105,
      QuotaNotificationType.backgroundRefreshUnavailable => 8106,
    };
  }

  String get title {
    return switch (this) {
      QuotaNotificationType.staleData => 'Quota data may be stale',
      QuotaNotificationType.lowFiveHourQuota => '5-hour quota is low',
      QuotaNotificationType.lowWeeklyQuota => 'Weekly quota is low',
      QuotaNotificationType.lowCredits => 'Credits are low',
      QuotaNotificationType.refreshFailed => 'Last refresh failed',
      QuotaNotificationType.backgroundRefreshUnavailable =>
        'Open the app to refresh quota',
    };
  }

  String get payload {
    return switch (this) {
      QuotaNotificationType.staleData => 'quota',
      QuotaNotificationType.lowFiveHourQuota => 'quota',
      QuotaNotificationType.lowWeeklyQuota => 'quota',
      QuotaNotificationType.lowCredits => 'quota',
      QuotaNotificationType.refreshFailed => 'web_login',
      QuotaNotificationType.backgroundRefreshUnavailable => 'web_login',
    };
  }
}

QuotaNotificationType quotaNotificationTypeFromStorageKey(String? value) {
  return QuotaNotificationType.values.firstWhere(
    (type) => type.storageKey == value,
    orElse: () => QuotaNotificationType.staleData,
  );
}
