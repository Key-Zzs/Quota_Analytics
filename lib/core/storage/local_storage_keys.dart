class LocalStorageKeys {
  const LocalStorageKeys._();

  static const quotaLatestSnapshot = 'quota.latest_snapshot.v1';
  static const quotaSnapshotHistory = 'quota.snapshot_history.v1';
  static const appSettings = 'settings.app_settings.v1';
  static const extractedPageText = 'extraction.last_page_text.v1';

  static const allAppKeys = <String>[
    quotaLatestSnapshot,
    quotaSnapshotHistory,
    appSettings,
    extractedPageText,
  ];
}
