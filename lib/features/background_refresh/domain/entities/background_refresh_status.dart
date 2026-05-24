enum BackgroundRefreshStatus {
  disabled,
  scheduled,
  running,
  notifyOnly,
  skippedNoSafeDataSource,
  skippedCooldown,
  staleDataNotificationSent,
  lowQuotaNotificationSent,
  refreshFailureNotificationSent,
  completedNoAction,
  failed;

  String get storageKey => name;

  String get label {
    return switch (this) {
      BackgroundRefreshStatus.disabled => 'disabled',
      BackgroundRefreshStatus.scheduled => 'scheduled',
      BackgroundRefreshStatus.running => 'running',
      BackgroundRefreshStatus.notifyOnly => 'notify only',
      BackgroundRefreshStatus.skippedNoSafeDataSource =>
        'skipped no safe data source',
      BackgroundRefreshStatus.skippedCooldown => 'skipped cooldown',
      BackgroundRefreshStatus.staleDataNotificationSent =>
        'stale data notification sent',
      BackgroundRefreshStatus.lowQuotaNotificationSent =>
        'low quota notification sent',
      BackgroundRefreshStatus.refreshFailureNotificationSent =>
        'refresh failure notification sent',
      BackgroundRefreshStatus.completedNoAction => 'completed no action',
      BackgroundRefreshStatus.failed => 'failed',
    };
  }
}

BackgroundRefreshStatus backgroundRefreshStatusFromStorageKey(String? value) {
  return BackgroundRefreshStatus.values.firstWhere(
    (status) => status.storageKey == value,
    orElse: () => BackgroundRefreshStatus.failed,
  );
}
