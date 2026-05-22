import '../../../../core/serialization/date_time_converter.dart';
import '../../domain/entities/quota_window.dart';

class QuotaWindowModel extends QuotaWindow {
  const QuotaWindowModel({
    required super.label,
    required super.used,
    required super.limit,
    required super.remaining,
    required super.remainingRatio,
    required super.resetAt,
    required super.status,
  });

  factory QuotaWindowModel.empty(String label) {
    return QuotaWindowModel(
      label: label,
      used: null,
      limit: null,
      remaining: null,
      remainingRatio: null,
      resetAt: null,
      status: QuotaWindowStatus.unknown,
    );
  }

  factory QuotaWindowModel.fromEntity(QuotaWindow window) {
    return QuotaWindowModel(
      label: window.label,
      used: window.used,
      limit: window.limit,
      remaining: window.remaining,
      remainingRatio: window.remainingRatio,
      resetAt: window.resetAt,
      status: window.status,
    );
  }

  factory QuotaWindowModel.fromJson(
    Map<String, Object?> json, {
    required String fallbackLabel,
  }) {
    final label = _readString(json['label']) ?? fallbackLabel;
    final used = _readInt(json['used']);
    final limit = _readInt(json['limit']);
    final remaining =
        _readInt(json['remaining']) ??
        QuotaWindow.fromUsage(
          label: label,
          used: used,
          limit: limit,
          resetAt: null,
        ).remaining;
    final remainingRatio =
        _readDouble(json['remainingRatio']) ??
        _remainingRatio(remaining: remaining, limit: limit);
    final statusValue = _readString(json['status']);
    final status = statusValue == null
        ? QuotaWindow.statusForRemainingRatio(remainingRatio)
        : quotaWindowStatusFromStorageKey(statusValue);

    return QuotaWindowModel(
      label: label,
      used: used,
      limit: limit,
      remaining: remaining,
      remainingRatio: remainingRatio,
      resetAt: dateTimeFromIso8601(json['resetAt']),
      status: status,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'label': label,
      'used': used,
      'limit': limit,
      'remaining': remaining,
      'remainingRatio': remainingRatio,
      'resetAt': dateTimeToIso8601(resetAt),
      'status': status.storageKey,
    };
  }

  static String? _readString(Object? value) {
    return value is String ? value : null;
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

  static double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  static double? _remainingRatio({
    required int? remaining,
    required int? limit,
  }) {
    if (remaining == null || limit == null || limit <= 0) {
      return null;
    }
    return remaining / limit;
  }
}
