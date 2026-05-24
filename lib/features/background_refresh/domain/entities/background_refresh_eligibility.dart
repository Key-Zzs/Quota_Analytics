enum BackgroundRefreshEligibilityStatus {
  allowed,
  notifyOnly,
  skippedDisabled,
  skippedNoBackgroundSafeDataSource,
  skippedCooldown,
  skippedBatteryOrSystemConstraint,
  failed;

  String get label {
    return switch (this) {
      BackgroundRefreshEligibilityStatus.allowed => 'allowed',
      BackgroundRefreshEligibilityStatus.notifyOnly => 'notify only',
      BackgroundRefreshEligibilityStatus.skippedDisabled => 'skipped disabled',
      BackgroundRefreshEligibilityStatus.skippedNoBackgroundSafeDataSource =>
        'skipped no background-safe data source',
      BackgroundRefreshEligibilityStatus.skippedCooldown => 'skipped cooldown',
      BackgroundRefreshEligibilityStatus.skippedBatteryOrSystemConstraint =>
        'skipped battery or system constraint',
      BackgroundRefreshEligibilityStatus.failed => 'failed',
    };
  }
}

class BackgroundRefreshEligibility {
  const BackgroundRefreshEligibility({
    required this.status,
    required this.evaluatedAt,
    required this.allowed,
    required this.notifyOnly,
    required this.warnings,
    required this.errors,
    this.remainingCooldown,
  });

  final BackgroundRefreshEligibilityStatus status;
  final DateTime evaluatedAt;
  final bool allowed;
  final bool notifyOnly;
  final List<String> warnings;
  final List<String> errors;
  final Duration? remainingCooldown;

  bool get shouldRunLocalCheck => allowed || notifyOnly;
}
