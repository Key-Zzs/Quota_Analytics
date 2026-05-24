enum QuotaNotificationThreshold {
  off,
  below20,
  below10,
  below5;

  String get storageKey => name;

  String get label {
    return switch (this) {
      QuotaNotificationThreshold.off => 'Off',
      QuotaNotificationThreshold.below20 => 'below 20%',
      QuotaNotificationThreshold.below10 => 'below 10%',
      QuotaNotificationThreshold.below5 => 'below 5%',
    };
  }

  double? get ratio {
    return switch (this) {
      QuotaNotificationThreshold.off => null,
      QuotaNotificationThreshold.below20 => 0.20,
      QuotaNotificationThreshold.below10 => 0.10,
      QuotaNotificationThreshold.below5 => 0.05,
    };
  }

  int? get percentage {
    final value = ratio;
    return value == null ? null : (value * 100).round();
  }

  bool get isOff => this == QuotaNotificationThreshold.off;
}

QuotaNotificationThreshold quotaNotificationThresholdFromStorageKey(
  String? value,
) {
  return QuotaNotificationThreshold.values.firstWhere(
    (threshold) => threshold.storageKey == value,
    orElse: () => QuotaNotificationThreshold.off,
  );
}
