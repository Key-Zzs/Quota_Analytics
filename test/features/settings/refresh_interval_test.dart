import 'package:quota_analytics/features/settings/data/mock_settings_repository.dart';
import 'package:quota_analytics/features/settings/domain/entities/refresh_interval.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RefreshInterval exposes the expected options', () {
    expect(RefreshInterval.values.map((interval) => interval.label), [
      'Off',
      '5 minutes',
      '15 minutes',
      '30 minutes',
      '60 minutes',
    ]);
  });

  test('RefreshInterval maps known durations', () {
    expect(
      RefreshInterval.fromDuration(const Duration(minutes: 15)),
      RefreshInterval.fifteenMinutes,
    );
    expect(RefreshInterval.fromDuration(null), RefreshInterval.off);
  });

  test('MockSettingsRepository keeps settings in memory', () {
    final repository = MockSettingsRepository();

    expect(repository.autoRefreshEnabled, isFalse);
    expect(repository.refreshInterval, RefreshInterval.off);

    repository.setAutoRefreshEnabled(true);
    expect(repository.autoRefreshEnabled, isTrue);
    expect(repository.refreshInterval, RefreshInterval.fifteenMinutes);

    repository.setRefreshInterval(RefreshInterval.thirtyMinutes);
    expect(repository.autoRefreshEnabled, isTrue);
    expect(repository.refreshInterval, RefreshInterval.thirtyMinutes);

    repository.setRefreshInterval(RefreshInterval.off);
    expect(repository.autoRefreshEnabled, isFalse);
  });
}
