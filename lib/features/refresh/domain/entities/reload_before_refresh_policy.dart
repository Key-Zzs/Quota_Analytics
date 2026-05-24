class ReloadBeforeRefreshPolicy {
  const ReloadBeforeRefreshPolicy({
    required this.enabled,
    this.reloadTimeout = defaultReloadTimeout,
    this.pageSettleDelay = defaultPageSettleDelay,
    this.reloadCooldown = defaultReloadCooldown,
    this.maxConsecutiveReloadFailures = defaultMaxConsecutiveReloadFailures,
  });

  factory ReloadBeforeRefreshPolicy.manualDefault({bool enabled = true}) {
    return ReloadBeforeRefreshPolicy(enabled: enabled);
  }

  factory ReloadBeforeRefreshPolicy.foregroundAutoDefault({
    bool enabled = false,
  }) {
    return ReloadBeforeRefreshPolicy(enabled: enabled);
  }

  static const defaultReloadTimeout = Duration(seconds: 15);
  static const defaultPageSettleDelay = Duration(milliseconds: 800);
  static const defaultReloadCooldown = Duration(seconds: 30);
  static const defaultMaxConsecutiveReloadFailures = 3;

  final bool enabled;
  final Duration reloadTimeout;
  final Duration pageSettleDelay;
  final Duration reloadCooldown;
  final int maxConsecutiveReloadFailures;

  ReloadBeforeRefreshPolicy copyWith({
    bool? enabled,
    Duration? reloadTimeout,
    Duration? pageSettleDelay,
    Duration? reloadCooldown,
    int? maxConsecutiveReloadFailures,
  }) {
    return ReloadBeforeRefreshPolicy(
      enabled: enabled ?? this.enabled,
      reloadTimeout: reloadTimeout ?? this.reloadTimeout,
      pageSettleDelay: pageSettleDelay ?? this.pageSettleDelay,
      reloadCooldown: reloadCooldown ?? this.reloadCooldown,
      maxConsecutiveReloadFailures:
          maxConsecutiveReloadFailures ?? this.maxConsecutiveReloadFailures,
    );
  }
}
