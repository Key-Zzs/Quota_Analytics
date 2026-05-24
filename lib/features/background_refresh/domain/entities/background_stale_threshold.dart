enum BackgroundStaleThreshold {
  off,
  thirtyMinutes,
  oneHour,
  twoHours,
  sixHours;

  String get storageKey => name;

  String get label {
    return switch (this) {
      BackgroundStaleThreshold.off => 'Off',
      BackgroundStaleThreshold.thirtyMinutes => '30 minutes',
      BackgroundStaleThreshold.oneHour => '1 hour',
      BackgroundStaleThreshold.twoHours => '2 hours',
      BackgroundStaleThreshold.sixHours => '6 hours',
    };
  }

  Duration? get duration {
    return switch (this) {
      BackgroundStaleThreshold.off => null,
      BackgroundStaleThreshold.thirtyMinutes => const Duration(minutes: 30),
      BackgroundStaleThreshold.oneHour => const Duration(hours: 1),
      BackgroundStaleThreshold.twoHours => const Duration(hours: 2),
      BackgroundStaleThreshold.sixHours => const Duration(hours: 6),
    };
  }

  bool get isOff => this == BackgroundStaleThreshold.off;
}

BackgroundStaleThreshold backgroundStaleThresholdFromStorageKey(String? value) {
  return BackgroundStaleThreshold.values.firstWhere(
    (threshold) => threshold.storageKey == value,
    orElse: () => BackgroundStaleThreshold.off,
  );
}
