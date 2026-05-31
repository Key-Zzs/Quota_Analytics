import 'package:flutter/foundation.dart';

import '../../../../core/security/sensitive_data_policy.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../domain/entities/widget_export_metadata.dart';
import '../../domain/entities/widget_export_status.dart';
import '../../domain/entities/widget_snapshot_summary.dart';
import '../../domain/entities/widget_shell_status.dart';
import '../../domain/entities/widget_update_result.dart';
import '../../domain/usecases/clear_widget_summary.dart';
import '../../domain/usecases/export_widget_summary.dart';
import '../../domain/usecases/get_widget_summary.dart';
import '../../domain/usecases/notify_widget_update.dart';

class WidgetExportController extends ChangeNotifier {
  WidgetExportController({
    required ExportWidgetSummary exportWidgetSummary,
    required GetWidgetSummary getWidgetSummary,
    required ClearWidgetSummary clearWidgetSummary,
    required NotifyWidgetUpdate notifyWidgetUpdate,
  }) : _exportWidgetSummary = exportWidgetSummary,
       _getWidgetSummary = getWidgetSummary,
       _clearWidgetSummary = clearWidgetSummary,
       _notifyWidgetUpdate = notifyWidgetUpdate;

  final ExportWidgetSummary _exportWidgetSummary;
  final GetWidgetSummary _getWidgetSummary;
  final ClearWidgetSummary _clearWidgetSummary;
  final NotifyWidgetUpdate _notifyWidgetUpdate;

  WidgetSnapshotSummary? _summary;
  WidgetExportMetadata _metadata = WidgetExportMetadata.initial();
  WidgetShellStatus _widgetShellStatus = WidgetShellStatus.unknown();
  WidgetUpdateResult _lastWidgetUpdateResult = WidgetUpdateResult.idle();
  bool _isBusy = false;
  String? _message;
  String? _lastError;

  WidgetSnapshotSummary? get summary => _summary;
  WidgetExportMetadata get metadata => _metadata;
  WidgetShellStatus get widgetShellStatus => _widgetShellStatus;
  WidgetUpdateResult get lastWidgetUpdateResult => _lastWidgetUpdateResult;
  bool get isBusy => _isBusy;
  String? get message => _message;
  String? get lastError => _lastError;
  String? get lastWidgetUpdateError => _lastWidgetUpdateResult.safeError;
  bool get exportEnabled => true;

  Future<void> load() async {
    try {
      _summary = await _getWidgetSummary();
      _metadata = await _getWidgetSummary.metadata();
      _widgetShellStatus = await _notifyWidgetUpdate.getShellStatus();
      _lastError = _metadata.lastExportError;
      _message = null;
    } on Object catch (error) {
      _lastError = SensitiveDataPolicy.sanitizeLogText(error.toString());
      _metadata = _metadata.copyWith(
        status: WidgetExportStatus.failed,
        lastExportError: _lastError,
      );
    }
    notifyListeners();
  }

  Future<void> exportNow(QuotaSnapshot? snapshot) async {
    if (_isBusy) {
      return;
    }
    if (snapshot == null) {
      _message = null;
      _lastError = 'No data';
      _metadata = _metadata.copyWith(
        status: WidgetExportStatus.failed,
        lastExportError: _lastError,
      );
      notifyListeners();
      return;
    }

    _isBusy = true;
    _message = null;
    _lastError = null;
    notifyListeners();

    try {
      final result = await _exportWidgetSummary(snapshot);
      _summary = result.summary ?? await _getWidgetSummary();
      _metadata = await _getWidgetSummary.metadata();
      _recordWidgetUpdateResult(result.widgetUpdateResult);
      _lastError = result.safeError ?? _metadata.lastExportError;
      _message = result.success
          ? 'Widget summary exported and widget update signaled.'
          : 'Widget summary export failed.';
    } on Object catch (error) {
      _lastError = SensitiveDataPolicy.sanitizeLogText(error.toString());
      _metadata = _metadata.copyWith(
        status: WidgetExportStatus.failed,
        lastExportError: _lastError,
      );
      _message = 'Widget summary export failed.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> clearSummary() async {
    if (_isBusy) {
      return;
    }

    _isBusy = true;
    _message = null;
    _lastError = null;
    notifyListeners();

    try {
      final result = await _clearWidgetSummary();
      _summary = null;
      _metadata = await _getWidgetSummary.metadata();
      _recordWidgetUpdateResult(result.widgetUpdateResult);
      _lastError = result.safeError ?? _metadata.lastExportError;
      _message = result.success ? null : 'Widget summary clear failed.';
      if (result.status == WidgetExportStatus.cleared) {
        _message = 'Widget summary cleared.';
      }
    } on Object catch (error) {
      _lastError = SensitiveDataPolicy.sanitizeLogText(error.toString());
      _metadata = _metadata.copyWith(
        status: WidgetExportStatus.failed,
        lastExportError: _lastError,
      );
      _message = 'Widget summary clear failed.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> updateWidgetsNow() async {
    if (_isBusy) {
      return;
    }

    _isBusy = true;
    _message = null;
    _lastError = null;
    notifyListeners();

    try {
      final result = await _notifyWidgetUpdate();
      _recordWidgetUpdateResult(result);
      _widgetShellStatus = await _notifyWidgetUpdate.getShellStatus();
      _message = result.failed
          ? 'Android widget update signal failed.'
          : 'Android widget update signal sent.';
    } on Object catch (error) {
      _recordWidgetUpdateResult(
        WidgetUpdateResult.failed(
          operation: 'update_widgets',
          sentAt: DateTime.now(),
          safeError: SensitiveDataPolicy.sanitizeLogText(error.toString()),
        ),
      );
      _message = 'Android widget update signal failed.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _recordWidgetUpdateResult(WidgetUpdateResult? result) {
    if (result == null) {
      return;
    }
    _lastWidgetUpdateResult = result;
  }
}
