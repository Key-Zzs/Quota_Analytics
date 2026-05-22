enum RefreshInterval {
  off(null, 'Off'),
  fiveMinutes(Duration(minutes: 5), '5 minutes'),
  fifteenMinutes(Duration(minutes: 15), '15 minutes'),
  thirtyMinutes(Duration(minutes: 30), '30 minutes'),
  sixtyMinutes(Duration(minutes: 60), '60 minutes');

  const RefreshInterval(this.duration, this.label);

  final Duration? duration;
  final String label;

  bool get isOff => this == RefreshInterval.off;

  String get storageKey => name;

  static RefreshInterval fromDuration(Duration? duration) {
    return RefreshInterval.values.firstWhere(
      (interval) => interval.duration == duration,
      orElse: () => RefreshInterval.off,
    );
  }
}

RefreshInterval refreshIntervalFromStorageKey(String? value) {
  return RefreshInterval.values.firstWhere(
    (interval) => interval.storageKey == value,
    orElse: () => RefreshInterval.off,
  );
}
