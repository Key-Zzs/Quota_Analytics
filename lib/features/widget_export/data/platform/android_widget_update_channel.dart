import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/platform/runtime_platform.dart';
import '../../../../core/security/sensitive_data_policy.dart';
import '../../../../core/time/clock.dart';
import '../../domain/entities/widget_shell_status.dart';
import '../../domain/entities/widget_snapshot_summary.dart';
import '../../domain/entities/widget_update_result.dart';
import '../../domain/entities/widget_update_reason.dart';
import '../../domain/repositories/widget_update_notifier.dart';
import '../models/widget_snapshot_summary_model.dart';

typedef AndroidRuntimeProvider = bool Function();

class AndroidWidgetUpdateChannel implements WidgetUpdateNotifier {
  AndroidWidgetUpdateChannel({
    MethodChannel channel = const MethodChannel(_channelName),
    AndroidRuntimeProvider? isAndroidProvider,
    Clock clock = const SystemClock(),
  }) : _channel = channel,
       _isAndroidProvider = isAndroidProvider ?? _defaultIsRuntimeAndroid,
       _clock = clock;

  static const channelName = 'quota_analytics/widget';
  static const _channelName = channelName;
  static const _methodSaveSummary = 'saveQuotaWidgetSummary';
  static const _methodClearSummary = 'clearQuotaWidgetSummary';
  static const _methodUpdateWidgets = 'updateQuotaWidgets';
  static const _methodGetStatus = 'getQuotaWidgetStatus';

  final MethodChannel _channel;
  final AndroidRuntimeProvider _isAndroidProvider;
  final Clock _clock;

  bool get _isAndroid => _isAndroidProvider();

  @override
  Future<WidgetUpdateResult> syncSummary(WidgetSnapshotSummary summary) async {
    const operation = 'sync_summary';
    if (!_isAndroid) {
      return _skipped(operation);
    }

    final summaryJson = jsonEncode(
      WidgetSnapshotSummaryModel.fromEntity(summary).toJson(),
    );
    return _invoke(
      operation: operation,
      method: _methodSaveSummary,
      arguments: <String, Object?>{'summaryJson': summaryJson},
    );
  }

  @override
  Future<WidgetUpdateResult> clearSummary() async {
    const operation = 'clear_summary';
    if (!_isAndroid) {
      return _skipped(operation);
    }
    return _invoke(operation: operation, method: _methodClearSummary);
  }

  @override
  Future<WidgetUpdateResult> updateWidgets({
    String reason = WidgetUpdateReason.unspecified,
  }) async {
    const operation = 'update_widgets';
    if (!_isAndroid) {
      return _skipped(operation, reason: reason);
    }
    return _invoke(
      operation: operation,
      method: _methodUpdateWidgets,
      reason: reason,
      arguments: <String, Object?>{
        'reason': reason,
        'timestamp': _clock.now().toIso8601String(),
      },
    );
  }

  @override
  Future<WidgetShellStatus> getShellStatus() async {
    if (!_isAndroid) {
      return WidgetShellStatus.unknown(safeError: 'non-Android platform');
    }

    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        _methodGetStatus,
      );
      if (raw == null) {
        return WidgetShellStatus.unknown(safeError: 'empty platform response');
      }
      final count = raw['installedWidgetCount'];
      return WidgetShellStatus(
        available: raw['available'] as bool?,
        installedWidgetCount: count is int ? count : null,
        hasInstalledWidgets: raw['hasInstalledWidgets'] as bool?,
        safeError: null,
      );
    } on Object catch (error) {
      return WidgetShellStatus.unknown(safeError: _safeError(error));
    }
  }

  Future<WidgetUpdateResult> _invoke({
    required String operation,
    required String method,
    String? reason,
    Object? arguments,
  }) async {
    final sentAt = _clock.now();
    try {
      await _channel.invokeMethod<void>(method, arguments);
      return WidgetUpdateResult.success(
        operation: operation,
        reason: reason,
        sentAt: sentAt,
      );
    } on Object catch (error) {
      return WidgetUpdateResult.failed(
        operation: operation,
        reason: reason,
        sentAt: sentAt,
        safeError: _safeError(error),
      );
    }
  }

  WidgetUpdateResult _skipped(String operation, {String? reason}) {
    return WidgetUpdateResult.skipped(
      operation: operation,
      reason: reason,
      sentAt: _clock.now(),
      safeError: 'non-Android platform',
    );
  }

  String _safeError(Object error) {
    return SensitiveDataPolicy.sanitizeLogText(error.toString());
  }
}

bool _defaultIsRuntimeAndroid() => isRuntimeAndroid;
