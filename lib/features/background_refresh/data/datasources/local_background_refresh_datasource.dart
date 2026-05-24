import 'dart:convert';

import '../../../../core/serialization/date_time_converter.dart';
import '../../../../core/storage/json_storage.dart';
import '../../../../core/storage/local_storage_keys.dart';
import '../../../../core/time/clock.dart';
import '../../../quota/data/models/quota_window_model.dart';
import '../../../quota/domain/entities/parser_confidence.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../../quota/domain/entities/quota_source.dart';
import '../../../quota/domain/entities/quota_window.dart';
import '../../../refresh/domain/entities/manual_refresh_status.dart';
import '../../domain/entities/background_refresh_result.dart';
import '../../domain/entities/background_refresh_settings.dart';
import '../../domain/entities/refresh_failure_metadata.dart';

class LocalBackgroundRefreshDataSource {
  LocalBackgroundRefreshDataSource({
    required this.storage,
    required this.clock,
  });

  final JsonStorage storage;
  final Clock clock;

  Future<BackgroundRefreshSettings?> loadSettings() async {
    final raw = await storage.readString(
      LocalStorageKeys.backgroundRefreshSettings,
    );
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('background settings root is not a map');
      }
      return BackgroundRefreshSettings.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
        fallbackUpdatedAt: clock.now(),
      );
    } on Object {
      await storage.remove(LocalStorageKeys.backgroundRefreshSettings);
      return null;
    }
  }

  Future<BackgroundRefreshSettings> saveSettings(
    BackgroundRefreshSettings settings,
  ) async {
    await storage.writeString(
      LocalStorageKeys.backgroundRefreshSettings,
      jsonEncode(settings.toJson()),
    );
    return settings;
  }

  Future<void> clearSettings() {
    return storage.remove(LocalStorageKeys.backgroundRefreshSettings);
  }

  Future<QuotaSnapshot?> loadLatestSnapshotForBackground() async {
    final raw = await storage.readString(LocalStorageKeys.quotaLatestSnapshot);
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('snapshot root is not a map');
      }
      final json = decoded.map((key, value) => MapEntry(key.toString(), value));
      return QuotaSnapshot(
        id: _readString(json['id']) ?? 'background-local-snapshot',
        accountLabel: 'Local snapshot',
        source: quotaSourceFromStorageKey(_readString(json['source'])),
        parserConfidence: parserConfidenceFromStorageKey(
          _readString(json['parserConfidence']),
        ),
        fiveHourWindow: _readWindow(
          json['fiveHourWindow'],
          fallbackLabel: '5-hour window',
        ),
        weeklyWindow: _readWindow(
          json['weeklyWindow'],
          fallbackLabel: 'Weekly window',
        ),
        creditsRemaining: _readDouble(json['creditsRemaining']),
        creditsTotal: _readDouble(json['creditsTotal']),
        capturedAt:
            dateTimeFromIso8601(json['capturedAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        nextSuggestedRefreshAt: dateTimeFromIso8601(
          json['nextSuggestedRefreshAt'],
        ),
        rawDebugText: null,
      );
    } on Object {
      return null;
    }
  }

  Future<RefreshFailureMetadata> loadLastRefreshFailureMetadata() async {
    final raw = await storage.readString(LocalStorageKeys.manualRefreshResult);
    if (raw == null) {
      return RefreshFailureMetadata.none;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return RefreshFailureMetadata.none;
      }
      final json = decoded.map((key, value) => MapEntry(key.toString(), value));
      final status = manualRefreshStatusFromStorageKey(
        _readString(json['status']),
      );
      final failed = switch (status) {
        ManualRefreshStatus.blocked ||
        ManualRefreshStatus.extractionFailed ||
        ManualRefreshStatus.parseFailed ||
        ManualRefreshStatus.lowConfidence ||
        ManualRefreshStatus.failed => true,
        _ => false,
      };
      if (!failed) {
        return RefreshFailureMetadata.none;
      }
      return RefreshFailureMetadata(
        failed: true,
        occurredAt:
            dateTimeFromIso8601(json['finishedAt']) ??
            dateTimeFromIso8601(json['startedAt']),
        statusLabel: status.label,
      );
    } on Object {
      return RefreshFailureMetadata.none;
    }
  }

  Future<BackgroundRefreshResult?> loadLastResult() async {
    final raw = await storage.readString(
      LocalStorageKeys.backgroundRefreshResult,
    );
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('background result root is not a map');
      }
      return BackgroundRefreshResult.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on Object {
      await storage.remove(LocalStorageKeys.backgroundRefreshResult);
      return null;
    }
  }

  Future<BackgroundRefreshResult> saveLastResult(
    BackgroundRefreshResult result,
  ) async {
    await storage.writeString(
      LocalStorageKeys.backgroundRefreshResult,
      jsonEncode(result.toJson()),
    );
    return result;
  }

  Future<void> clearLastResult() {
    return storage.remove(LocalStorageKeys.backgroundRefreshResult);
  }

  QuotaWindow _readWindow(Object? value, {required String fallbackLabel}) {
    if (value is! Map) {
      return QuotaWindowModel.empty(fallbackLabel);
    }
    final json = value.map(
      (key, mapValue) => MapEntry(key.toString(), mapValue),
    );
    return QuotaWindowModel(
      label: _readString(json['label']) ?? fallbackLabel,
      used: _readInt(json['used']),
      limit: _readInt(json['limit']),
      remaining: _readInt(json['remaining']),
      remainingRatio: _readDouble(json['remainingRatio']),
      resetAt: dateTimeFromIso8601(json['resetAt']),
      status: quotaWindowStatusFromStorageKey(_readString(json['status'])),
    );
  }

  String? _readString(Object? value) {
    return value is String ? value : null;
  }

  int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }
}
