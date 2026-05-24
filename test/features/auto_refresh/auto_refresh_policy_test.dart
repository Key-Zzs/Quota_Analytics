import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/auto_refresh/domain/entities/auto_refresh_policy.dart';
import 'package:quota_analytics/features/settings/domain/entities/refresh_interval.dart';

void main() {
  test('nextEligibleAt follows 5/15/30/60 minute intervals', () {
    const policy = AutoRefreshPolicy();
    final successAt = DateTime(2026, 1, 1, 12);

    expect(
      policy.nextEligibleAt(
        lastSuccessAt: successAt,
        interval: RefreshInterval.fiveMinutes,
      ),
      DateTime(2026, 1, 1, 12, 5),
    );
    expect(
      policy.nextEligibleAt(
        lastSuccessAt: successAt,
        interval: RefreshInterval.fifteenMinutes,
      ),
      DateTime(2026, 1, 1, 12, 15),
    );
    expect(
      policy.nextEligibleAt(
        lastSuccessAt: successAt,
        interval: RefreshInterval.thirtyMinutes,
      ),
      DateTime(2026, 1, 1, 12, 30),
    );
    expect(
      policy.nextEligibleAt(
        lastSuccessAt: successAt,
        interval: RefreshInterval.sixtyMinutes,
      ),
      DateTime(2026, 1, 1, 13),
    );
  });

  test('lastSuccessAt null means no scheduled wait and is eligible now', () {
    const policy = AutoRefreshPolicy();
    final now = DateTime(2026, 1, 1, 12);

    expect(
      policy.nextEligibleAt(
        lastSuccessAt: null,
        interval: RefreshInterval.fiveMinutes,
      ),
      isNull,
    );
    expect(
      policy.intervalReached(
        now: now,
        lastSuccessAt: null,
        interval: RefreshInterval.fiveMinutes,
      ),
      isTrue,
    );
  });

  test('cooldown blocks checks until expiry', () {
    const policy = AutoRefreshPolicy(failureCooldown: Duration(minutes: 5));
    final failedAt = DateTime(2026, 1, 1, 12);
    final cooldownUntil = policy.cooldownUntil(failedAt);

    expect(cooldownUntil, DateTime(2026, 1, 1, 12, 5));
    expect(
      policy.isInCooldown(
        now: DateTime(2026, 1, 1, 12, 4, 59),
        cooldownUntil: cooldownUntil,
      ),
      isTrue,
    );
    expect(
      policy.isInCooldown(
        now: DateTime(2026, 1, 1, 12, 5),
        cooldownUntil: cooldownUntil,
      ),
      isFalse,
    );
  });
}
