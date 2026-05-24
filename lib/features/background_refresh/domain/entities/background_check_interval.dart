enum BackgroundCheckInterval {
  off,
  thirtyMinutes,
  oneHour,
  twoHours,
  sixHours;

  String get storageKey => name;

  String get label {
    return switch (this) {
      BackgroundCheckInterval.off => 'Off',
      BackgroundCheckInterval.thirtyMinutes => '30 minutes',
      BackgroundCheckInterval.oneHour => '1 hour',
      BackgroundCheckInterval.twoHours => '2 hours',
      BackgroundCheckInterval.sixHours => '6 hours',
    };
  }

  Duration? get duration {
    return switch (this) {
      BackgroundCheckInterval.off => null,
      BackgroundCheckInterval.thirtyMinutes => const Duration(minutes: 30),
      BackgroundCheckInterval.oneHour => const Duration(hours: 1),
      BackgroundCheckInterval.twoHours => const Duration(hours: 2),
      BackgroundCheckInterval.sixHours => const Duration(hours: 6),
    };
  }

  bool get isOff => this == BackgroundCheckInterval.off;
}

BackgroundCheckInterval backgroundCheckIntervalFromStorageKey(String? value) {
  return BackgroundCheckInterval.values.firstWhere(
    (interval) => interval.storageKey == value,
    orElse: () => BackgroundCheckInterval.off,
  );
}
