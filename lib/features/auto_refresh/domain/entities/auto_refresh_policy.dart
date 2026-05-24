import '../../../settings/domain/entities/refresh_interval.dart';

class AutoRefreshPolicy {
  const AutoRefreshPolicy({
    this.checkInterval = const Duration(seconds: 60),
    this.failureCooldown = const Duration(minutes: 5),
  });

  final Duration checkInterval;
  final Duration failureCooldown;

  DateTime? nextEligibleAt({
    required DateTime? lastSuccessAt,
    required RefreshInterval interval,
  }) {
    final duration = interval.duration;
    if (duration == null || lastSuccessAt == null) {
      return null;
    }
    return lastSuccessAt.add(duration);
  }

  bool intervalReached({
    required DateTime now,
    required DateTime? lastSuccessAt,
    required RefreshInterval interval,
  }) {
    final next = nextEligibleAt(
      lastSuccessAt: lastSuccessAt,
      interval: interval,
    );
    return next == null || !now.isBefore(next);
  }

  DateTime cooldownUntil(DateTime now) => now.add(failureCooldown);

  bool isInCooldown({required DateTime now, required DateTime? cooldownUntil}) {
    return cooldownUntil != null && now.isBefore(cooldownUntil);
  }
}
