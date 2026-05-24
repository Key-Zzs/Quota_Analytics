import 'package:flutter/foundation.dart';

import '../../../../core/permissions/notification_permission_service.dart';
import '../../../../core/time/clock.dart';
import '../../../notifications/domain/entities/notification_metadata.dart';
import '../../../notifications/domain/entities/notification_settings.dart';
import '../../../notifications/domain/entities/quota_notification_threshold.dart';
import '../../../notifications/domain/repositories/notification_repository.dart';
import '../../domain/entities/background_check_interval.dart';
import '../../domain/entities/background_refresh_mode.dart';
import '../../domain/entities/background_refresh_result.dart';
import '../../domain/entities/background_refresh_settings.dart';
import '../../domain/entities/background_stale_threshold.dart';
import '../../domain/repositories/background_refresh_repository.dart';
import '../../domain/usecases/cancel_background_refresh.dart';
import '../../domain/usecases/run_background_refresh_check.dart';
import '../../domain/usecases/schedule_background_refresh.dart';

enum BackgroundRefreshSettingsStatus { loading, ready, saving, running, error }

class BackgroundRefreshSettingsController extends ChangeNotifier {
  BackgroundRefreshSettingsController({
    required BackgroundRefreshRepository backgroundRepository,
    required NotificationRepository notificationRepository,
    required RunBackgroundRefreshCheck runBackgroundRefreshCheck,
    required Clock clock,
  }) : _backgroundRepository = backgroundRepository,
       _notificationRepository = notificationRepository,
       _runBackgroundRefreshCheck = runBackgroundRefreshCheck,
       _scheduleBackgroundRefresh = ScheduleBackgroundRefresh(
         backgroundRepository,
       ),
       _cancelBackgroundRefresh = CancelBackgroundRefresh(backgroundRepository),
       _clock = clock;

  final BackgroundRefreshRepository _backgroundRepository;
  final NotificationRepository _notificationRepository;
  final RunBackgroundRefreshCheck _runBackgroundRefreshCheck;
  final ScheduleBackgroundRefresh _scheduleBackgroundRefresh;
  final CancelBackgroundRefresh _cancelBackgroundRefresh;
  final Clock _clock;

  BackgroundRefreshSettingsStatus _status =
      BackgroundRefreshSettingsStatus.loading;
  BackgroundRefreshSettings? _settings;
  BackgroundRefreshResult? _lastResult;
  NotificationPermissionStatus _permissionStatus =
      NotificationPermissionStatus.unknown;
  NotificationMetadata _notificationMetadata = NotificationMetadata.empty();
  bool _backgroundSafeDataSourceAvailable = false;
  String? _message;
  String? _errorMessage;

  BackgroundRefreshSettingsStatus get status => _status;
  BackgroundRefreshSettings get settings =>
      _settings ?? BackgroundRefreshSettings.defaults(_clock.now());
  BackgroundRefreshResult? get lastResult => _lastResult;
  NotificationPermissionStatus get permissionStatus => _permissionStatus;
  NotificationMetadata get notificationMetadata => _notificationMetadata;
  bool get backgroundSafeDataSourceAvailable =>
      _backgroundSafeDataSourceAvailable;
  String? get message => _message;
  String? get errorMessage => _errorMessage;
  bool get isBusy =>
      _status == BackgroundRefreshSettingsStatus.saving ||
      _status == BackgroundRefreshSettingsStatus.running;

  Future<void> load() async {
    _status = BackgroundRefreshSettingsStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _settings = await _backgroundRepository.getSettings();
      _lastResult = await _backgroundRepository.getLastResult();
      _notificationMetadata = await _notificationRepository.getMetadata();
      _permissionStatus = await _notificationRepository.getPermissionStatus();
      _backgroundSafeDataSourceAvailable = await _backgroundRepository
          .hasBackgroundSafeDataSource();
      _status = BackgroundRefreshSettingsStatus.ready;
    } on Object catch (error) {
      _status = BackgroundRefreshSettingsStatus.error;
      _errorMessage = 'Unable to load background refresh settings: $error';
    }
    notifyListeners();
  }

  void setMode(BackgroundRefreshMode mode) {
    _settings = settings.copyWith(mode: mode);
    _message = null;
    notifyListeners();
  }

  void setCheckInterval(BackgroundCheckInterval interval) {
    _settings = settings.copyWith(checkInterval: interval);
    _message = null;
    notifyListeners();
  }

  void setLocalNotificationsEnabled(bool value) {
    _settings = settings.copyWith(
      notificationSettings: settings.notificationSettings.copyWith(
        localNotificationsEnabled: value,
      ),
    );
    _message = null;
    notifyListeners();
  }

  void setStaleDataThreshold(BackgroundStaleThreshold threshold) {
    _settings = settings.copyWith(staleDataThreshold: threshold);
    _message = null;
    notifyListeners();
  }

  void setLowFiveHourQuotaThreshold(QuotaNotificationThreshold threshold) {
    _updateNotificationSettings(
      settings.notificationSettings.copyWith(
        lowFiveHourQuotaThreshold: threshold,
      ),
    );
  }

  void setLowWeeklyQuotaThreshold(QuotaNotificationThreshold threshold) {
    _updateNotificationSettings(
      settings.notificationSettings.copyWith(
        lowWeeklyQuotaThreshold: threshold,
      ),
    );
  }

  void setRefreshFailureReminderEnabled(bool value) {
    _updateNotificationSettings(
      settings.notificationSettings.copyWith(
        refreshFailureReminderEnabled: value,
      ),
    );
  }

  Future<void> requestNotificationPermission() async {
    _status = BackgroundRefreshSettingsStatus.saving;
    _message = null;
    _errorMessage = null;
    notifyListeners();
    try {
      _permissionStatus = await _notificationRepository.requestPermission();
      _status = BackgroundRefreshSettingsStatus.ready;
      _message = 'Notification permission ${_permissionStatus.label}';
    } on Object catch (error) {
      _status = BackgroundRefreshSettingsStatus.error;
      _errorMessage = 'Unable to request notification permission: $error';
    }
    notifyListeners();
  }

  Future<void> save() async {
    _status = BackgroundRefreshSettingsStatus.saving;
    _message = null;
    _errorMessage = null;
    notifyListeners();
    try {
      _settings = await _backgroundRepository.saveSettings(settings);
      if (settings.shouldSchedule) {
        await _scheduleBackgroundRefresh(settings);
      } else {
        await _cancelBackgroundRefresh();
      }
      _status = BackgroundRefreshSettingsStatus.ready;
      _message = settings.shouldSchedule
          ? 'Background refresh scheduled'
          : 'Background refresh disabled';
    } on Object catch (error) {
      _status = BackgroundRefreshSettingsStatus.error;
      _errorMessage = 'Unable to save background settings: $error';
    }
    notifyListeners();
  }

  Future<void> runNow() async {
    _status = BackgroundRefreshSettingsStatus.running;
    _message = null;
    _errorMessage = null;
    notifyListeners();
    try {
      _lastResult = await _runBackgroundRefreshCheck(now: _clock.now());
      _notificationMetadata = await _notificationRepository.getMetadata();
      _permissionStatus = await _notificationRepository.getPermissionStatus();
      _status = BackgroundRefreshSettingsStatus.ready;
      _message = 'Background check finished: ${_lastResult!.status.label}';
    } on Object catch (error) {
      _status = BackgroundRefreshSettingsStatus.error;
      _errorMessage = 'Unable to run background check: $error';
    }
    notifyListeners();
  }

  Future<void> clear() async {
    await _cancelBackgroundRefresh();
    await _backgroundRepository.clearSettings();
    await _backgroundRepository.clearLastResult();
    await _notificationRepository.clearMetadata();
    _settings = BackgroundRefreshSettings.defaults(_clock.now());
    _lastResult = null;
    _notificationMetadata = NotificationMetadata.empty();
    _message = 'Background refresh data cleared';
    notifyListeners();
  }

  void _updateNotificationSettings(NotificationSettings next) {
    _settings = settings.copyWith(notificationSettings: next);
    _message = null;
    notifyListeners();
  }
}
