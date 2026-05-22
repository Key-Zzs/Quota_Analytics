enum QuotaWindowStatus { ok, warning, critical, unknown }

extension QuotaWindowStatusLabel on QuotaWindowStatus {
  String get label {
    return switch (this) {
      QuotaWindowStatus.ok => 'ok',
      QuotaWindowStatus.warning => 'warning',
      QuotaWindowStatus.critical => 'critical',
      QuotaWindowStatus.unknown => 'unknown',
    };
  }
}

class QuotaWindow {
  const QuotaWindow({
    required this.label,
    required this.used,
    required this.limit,
    required this.remaining,
    required this.remainingRatio,
    required this.resetAt,
    required this.status,
  });

  factory QuotaWindow.fromUsage({
    required String label,
    required int? used,
    required int? limit,
    required DateTime? resetAt,
    QuotaWindowStatus? status,
  }) {
    final computedRemaining = _remainingFromUsage(used: used, limit: limit);
    final computedRatio = _remainingRatio(
      remaining: computedRemaining,
      limit: limit,
    );

    return QuotaWindow(
      label: label,
      used: used,
      limit: limit,
      remaining: computedRemaining,
      remainingRatio: computedRatio,
      resetAt: resetAt,
      status: status ?? statusForRemainingRatio(computedRatio),
    );
  }

  final String label;
  final int? used;
  final int? limit;
  final int? remaining;
  final double? remainingRatio;
  final DateTime? resetAt;
  final QuotaWindowStatus status;

  int? get remainingPercentage {
    final ratio = remainingRatio;
    if (ratio == null) {
      return null;
    }
    return (ratio * 100).round();
  }

  Map<String, Object?> toDebugMap() {
    return {
      'label': label,
      'used': used,
      'limit': limit,
      'remaining': remaining,
      'remainingRatio': remainingRatio,
      'resetAt': resetAt?.toIso8601String(),
      'status': status.name,
    };
  }

  static QuotaWindowStatus statusForRemainingRatio(double? ratio) {
    if (ratio == null) {
      return QuotaWindowStatus.unknown;
    }
    if (ratio <= 0.10) {
      return QuotaWindowStatus.critical;
    }
    if (ratio <= 0.25) {
      return QuotaWindowStatus.warning;
    }
    return QuotaWindowStatus.ok;
  }

  static int? _remainingFromUsage({required int? used, required int? limit}) {
    if (used == null || limit == null || limit <= 0) {
      return null;
    }
    final remaining = limit - used;
    if (remaining < 0) {
      return 0;
    }
    if (remaining > limit) {
      return limit;
    }
    return remaining;
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
