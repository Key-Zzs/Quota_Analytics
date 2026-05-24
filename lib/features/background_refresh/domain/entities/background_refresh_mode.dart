enum BackgroundRefreshMode {
  disabled,
  notifyOnly,
  backgroundSafeDataSourceOnly;

  String get storageKey => name;

  String get label {
    return switch (this) {
      BackgroundRefreshMode.disabled => 'Disabled',
      BackgroundRefreshMode.notifyOnly => 'Notify only',
      BackgroundRefreshMode.backgroundSafeDataSourceOnly =>
        'Background-safe data source only',
    };
  }

  String get shortDescription {
    return switch (this) {
      BackgroundRefreshMode.disabled =>
        'No background task and no background reminders.',
      BackgroundRefreshMode.notifyOnly =>
        'Checks saved local data and sends reminders only.',
      BackgroundRefreshMode.backgroundSafeDataSourceOnly =>
        'Reserved for a future official API, desktop agent, or extension sync.',
    };
  }
}

BackgroundRefreshMode backgroundRefreshModeFromStorageKey(String? value) {
  return BackgroundRefreshMode.values.firstWhere(
    (mode) => mode.storageKey == value,
    orElse: () => BackgroundRefreshMode.disabled,
  );
}
