import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/refresh/domain/entities/reload_before_refresh_policy.dart';

void main() {
  test('manual default behavior is enabled', () {
    final policy = ReloadBeforeRefreshPolicy.manualDefault();

    expect(policy.enabled, isTrue);
    expect(policy.reloadTimeout, const Duration(seconds: 15));
    expect(policy.pageSettleDelay, const Duration(milliseconds: 800));
    expect(policy.reloadCooldown, const Duration(seconds: 30));
    expect(policy.maxConsecutiveReloadFailures, 3);
  });

  test('foreground auto default behavior is disabled', () {
    final policy = ReloadBeforeRefreshPolicy.foregroundAutoDefault();

    expect(policy.enabled, isFalse);
    expect(policy.reloadTimeout, const Duration(seconds: 15));
    expect(policy.pageSettleDelay, const Duration(milliseconds: 800));
    expect(policy.reloadCooldown, const Duration(seconds: 30));
  });
}
