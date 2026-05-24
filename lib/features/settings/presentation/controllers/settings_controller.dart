import 'package:flutter/foundation.dart';

import '../../../refresh/domain/entities/manual_refresh_policy.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/refresh_interval.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/clear_app_settings.dart';
import '../../domain/usecases/get_app_settings.dart';
import '../../domain/usecases/save_app_settings.dart';

enum SettingsStatus { loading, ready, saving, error }

class SettingsController extends ChangeNotifier {
  SettingsController({required SettingsRepository repository})
    : _getSettings = GetAppSettings(repository),
      _saveSettings = SaveAppSettings(repository),
      _clearSettings = ClearAppSettings(repository);

  final GetAppSettings _getSettings;
  final SaveAppSettings _saveSettings;
  final ClearAppSettings _clearSettings;

  SettingsStatus _status = SettingsStatus.loading;
  AppSettings? _settings;
  String? _message;
  String? _errorMessage;
  DateTime? _lastLoadTime;
  DateTime? _lastSaveTime;

  SettingsStatus get status => _status;
  AppSettings? get settings => _settings;
  bool get autoRefreshEnabled => _settings?.autoRefreshEnabled ?? false;
  RefreshInterval get refreshInterval =>
      _settings?.refreshInterval ?? RefreshInterval.off;
  ManualRefreshPolicy get manualRefreshPolicy =>
      _settings?.manualRefreshPolicy ?? ManualRefreshPolicy.defaults();
  bool get autoSaveHighConfidenceManualRefresh =>
      manualRefreshPolicy.autoSaveHighConfidence;
  String? get message => _message;
  String? get errorMessage => _errorMessage;
  DateTime? get lastLoadTime => _lastLoadTime;
  DateTime? get lastSaveTime => _lastSaveTime;
  bool get isSaving => _status == SettingsStatus.saving;

  Future<void> load() async {
    _status = SettingsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _getSettings();
      _lastLoadTime = DateTime.now();
      _status = SettingsStatus.ready;
    } on Object catch (error) {
      _status = SettingsStatus.error;
      _errorMessage = 'Unable to load settings: $error';
    }

    notifyListeners();
  }

  void setAutoRefreshEnabled(bool value) {
    final current = _settings ?? AppSettings.defaults(DateTime.now());
    _settings = current.copyWith(
      autoRefreshEnabled: value,
      refreshInterval: value && current.refreshInterval.isOff
          ? RefreshInterval.fifteenMinutes
          : current.refreshInterval,
    );
    _message = null;
    notifyListeners();
  }

  void setRefreshInterval(RefreshInterval interval) {
    final current = _settings ?? AppSettings.defaults(DateTime.now());
    _settings = current.copyWith(
      autoRefreshEnabled: !interval.isOff,
      refreshInterval: interval,
    );
    _message = null;
    notifyListeners();
  }

  void setManualRefreshAutoSaveHighConfidence(bool value) {
    final current = _settings ?? AppSettings.defaults(DateTime.now());
    _settings = current.copyWith(
      manualRefreshPolicy: current.manualRefreshPolicy.copyWith(
        autoSaveHighConfidence: value,
      ),
    );
    _message = null;
    notifyListeners();
  }

  Future<void> save() async {
    final current = _settings;
    if (current == null) {
      return;
    }

    _status = SettingsStatus.saving;
    _message = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _saveSettings(current);
      _lastSaveTime = DateTime.now();
      _status = SettingsStatus.ready;
      _message = 'Settings saved';
    } on Object catch (error) {
      _status = SettingsStatus.error;
      _errorMessage = 'Unable to save settings: $error';
    }

    notifyListeners();
  }

  Future<void> clear() async {
    _status = SettingsStatus.saving;
    _message = null;
    _errorMessage = null;
    notifyListeners();

    try {
      await _clearSettings();
      _lastSaveTime = DateTime.now();
      _settings = AppSettings.defaults(DateTime.now());
      _status = SettingsStatus.ready;
      _message = 'Settings cleared';
    } on Object catch (error) {
      _status = SettingsStatus.error;
      _errorMessage = 'Unable to clear settings: $error';
    }

    notifyListeners();
  }
}
