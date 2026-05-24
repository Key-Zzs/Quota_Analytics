import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_status.dart';

void main() {
  test('idle status is stable default', () {
    expect(ManualRefreshStatus.idle.label, 'idle');
    expect(manualRefreshStatusFromStorageKey(null), ManualRefreshStatus.idle);
    expect(
      manualRefreshStatusFromStorageKey('missing'),
      ManualRefreshStatus.idle,
    );
  });

  test('active and terminal helpers classify transitions', () {
    expect(ManualRefreshStatus.checkingPage.isActive, isTrue);
    expect(ManualRefreshStatus.extractingText.isActive, isTrue);
    expect(ManualRefreshStatus.parsing.isActive, isTrue);
    expect(ManualRefreshStatus.saved.isTerminal, isTrue);
    expect(ManualRefreshStatus.lowConfidence.isTerminal, isTrue);
    expect(ManualRefreshStatus.idle.isTerminal, isFalse);
  });
}
