import '../../../../core/serialization/date_time_converter.dart';
import 'background_refresh_status.dart';

class BackgroundRefreshResult {
  const BackgroundRefreshResult({
    required this.status,
    required this.startedAt,
    required this.finishedAt,
    required this.warnings,
    required this.errors,
    required this.notificationsSent,
    required this.safeDataSourceUsed,
  });

  factory BackgroundRefreshResult.running(DateTime startedAt) {
    return BackgroundRefreshResult(
      status: BackgroundRefreshStatus.running,
      startedAt: startedAt,
      finishedAt: null,
      warnings: const [],
      errors: const [],
      notificationsSent: 0,
      safeDataSourceUsed: null,
    );
  }

  factory BackgroundRefreshResult.fromJson(Map<String, Object?> json) {
    final startedAt =
        dateTimeFromIso8601(json['startedAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return BackgroundRefreshResult(
      status: backgroundRefreshStatusFromStorageKey(
        _readString(json['status']),
      ),
      startedAt: startedAt,
      finishedAt: dateTimeFromIso8601(json['finishedAt']),
      warnings: _readStringList(json['warnings']),
      errors: _readStringList(json['errors']),
      notificationsSent: _readInt(json['notificationsSent']) ?? 0,
      safeDataSourceUsed: _readNullableString(json['safeDataSourceUsed']),
    );
  }

  final BackgroundRefreshStatus status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<String> warnings;
  final List<String> errors;
  final int notificationsSent;
  final String? safeDataSourceUsed;

  Duration? get duration {
    final finished = finishedAt;
    return finished?.difference(startedAt);
  }

  BackgroundRefreshResult finish({
    required BackgroundRefreshStatus status,
    required DateTime finishedAt,
    List<String>? warnings,
    List<String>? errors,
    int? notificationsSent,
    String? safeDataSourceUsed,
  }) {
    return BackgroundRefreshResult(
      status: status,
      startedAt: startedAt,
      finishedAt: finishedAt,
      warnings: warnings ?? this.warnings,
      errors: errors ?? this.errors,
      notificationsSent: notificationsSent ?? this.notificationsSent,
      safeDataSourceUsed: safeDataSourceUsed ?? this.safeDataSourceUsed,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'status': status.storageKey,
      'startedAt': dateTimeToIso8601(startedAt),
      'finishedAt': dateTimeToIso8601(finishedAt),
      'durationMs': duration?.inMilliseconds,
      'warnings': warnings,
      'errors': errors,
      'notificationsSent': notificationsSent,
      'safeDataSourceUsed': safeDataSourceUsed,
    };
  }

  static String? _readString(Object? value) {
    return value is String ? value : null;
  }

  static String? _readNullableString(Object? value) {
    final text = _readString(value)?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<String>().toList(growable: false);
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }
}
