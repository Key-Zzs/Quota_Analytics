class LocalStorageKeys {
  const LocalStorageKeys._();

  static const quotaLatestSnapshot = 'quota.latest_snapshot.v1';
  static const quotaSnapshotHistory = 'quota.snapshot_history.v1';
  static const appSettings = 'settings.app_settings.v1';
  static const extractedPageText = 'extraction.last_page_text.v1';
  static const manualRefreshResult = 'refresh.last_manual_result.v1';
  static const backgroundRefreshSettings =
      'background_refresh.settings.v1';
  static const backgroundRefreshResult = 'background_refresh.last_result.v1';
  static const notificationMetadata = 'notifications.metadata.v1';

  static const allAppKeys = <String>[
    quotaLatestSnapshot,
    quotaSnapshotHistory,
    appSettings,
    extractedPageText,
    manualRefreshResult,
    backgroundRefreshSettings,
    backgroundRefreshResult,
    notificationMetadata,
  ];
}
