class WidgetUpdateReason {
  const WidgetUpdateReason._();

  static const appStartup = 'appStartup';
  static const snapshotSaved = 'snapshotSaved';
  static const manualRefresh = 'manualRefresh';
  static const quotaPageRefresh = 'quotaPageRefresh';
  static const foregroundAutoRefresh = 'foregroundAutoRefresh';
  static const backgroundNotifyOnlyCheck = 'backgroundNotifyOnlyCheck';
  static const debugExport = 'debugExport';
  static const debugUpdate = 'debugUpdate';
  static const clearWidgetSummary = 'clearWidgetSummary';
  static const clearData = 'clearData';
  static const providerUpdate = 'providerUpdate';
  static const settingsChanged = 'settingsChanged';
  static const unspecified = 'unspecified';
}
