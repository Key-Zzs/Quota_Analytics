import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/storage/local_storage_keys.dart';
import 'package:quota_analytics/core/storage/shared_preferences_storage.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/settings/data/datasources/local_settings_datasource.dart';
import 'package:quota_analytics/features/settings/data/repositories/local_settings_repository.dart';
import 'package:quota_analytics/features/settings/domain/entities/app_settings.dart';
import 'package:quota_analytics/features/settings/domain/entities/refresh_interval.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns default settings when nothing is saved', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = await _buildRepository();

    final settings = await repository.getSettings();

    expect(settings.autoRefreshEnabled, isFalse);
    expect(settings.refreshInterval, RefreshInterval.off);
  });

  test('saves and loads settings', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = await _buildRepository();

    await repository.saveSettings(
      AppSettings(
        autoRefreshEnabled: true,
        refreshInterval: RefreshInterval.thirtyMinutes,
        manualRefreshPolicy: ManualRefreshPolicy.defaults(),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    final loaded = await repository.getSettings();

    expect(loaded.autoRefreshEnabled, isTrue);
    expect(loaded.refreshInterval, RefreshInterval.thirtyMinutes);
    expect(loaded.updatedAt, DateTime.utc(2026, 1, 1, 9));
  });

  test('clears settings back to defaults', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = await _buildRepository();

    await repository.saveSettings(
      AppSettings(
        autoRefreshEnabled: true,
        refreshInterval: RefreshInterval.fiveMinutes,
        manualRefreshPolicy: ManualRefreshPolicy.defaults(),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await repository.clearSettings();

    final loaded = await repository.getSettings();
    expect(loaded.autoRefreshEnabled, isFalse);
    expect(loaded.refreshInterval, RefreshInterval.off);
  });

  test('corrupted settings JSON falls back without crashing', () async {
    SharedPreferences.setMockInitialValues({
      LocalStorageKeys.appSettings: '{bad json',
    });
    final repository = await _buildRepository();

    final loaded = await repository.getSettings();

    expect(loaded.autoRefreshEnabled, isFalse);
    expect(loaded.refreshInterval, RefreshInterval.off);
  });

  test('RefreshInterval serializes as a string', () {
    expect(RefreshInterval.fifteenMinutes.storageKey, 'fifteenMinutes');
    expect(
      refreshIntervalFromStorageKey('sixtyMinutes'),
      RefreshInterval.sixtyMinutes,
    );
  });
}

Future<LocalSettingsRepository> _buildRepository() async {
  final clock = FixedClock(DateTime.utc(2026, 1, 1, 9));
  return LocalSettingsRepository(
    dataSource: LocalSettingsDataSource(
      storage: await SharedPreferencesStorage.create(),
      clock: clock,
    ),
    clock: clock,
  );
}
