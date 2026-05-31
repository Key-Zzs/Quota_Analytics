enum WidgetUpdateSignalStatus { idle, success, failed, skipped }

extension WidgetUpdateSignalStatusLabel on WidgetUpdateSignalStatus {
  String get label {
    return switch (this) {
      WidgetUpdateSignalStatus.idle => 'idle',
      WidgetUpdateSignalStatus.success => 'success',
      WidgetUpdateSignalStatus.failed => 'failed',
      WidgetUpdateSignalStatus.skipped => 'skipped',
    };
  }
}

class WidgetUpdateResult {
  const WidgetUpdateResult({
    required this.operation,
    required this.reason,
    required this.status,
    required this.sentAt,
    required this.safeError,
  });

  factory WidgetUpdateResult.idle() {
    return const WidgetUpdateResult(
      operation: 'none',
      reason: null,
      status: WidgetUpdateSignalStatus.idle,
      sentAt: null,
      safeError: null,
    );
  }

  factory WidgetUpdateResult.success({
    required String operation,
    required DateTime sentAt,
    String? reason,
  }) {
    return WidgetUpdateResult(
      operation: operation,
      reason: reason,
      status: WidgetUpdateSignalStatus.success,
      sentAt: sentAt,
      safeError: null,
    );
  }

  factory WidgetUpdateResult.failed({
    required String operation,
    required DateTime sentAt,
    required String safeError,
    String? reason,
  }) {
    return WidgetUpdateResult(
      operation: operation,
      reason: reason,
      status: WidgetUpdateSignalStatus.failed,
      sentAt: sentAt,
      safeError: safeError,
    );
  }

  factory WidgetUpdateResult.skipped({
    required String operation,
    DateTime? sentAt,
    String? safeError,
    String? reason,
  }) {
    return WidgetUpdateResult(
      operation: operation,
      reason: reason,
      status: WidgetUpdateSignalStatus.skipped,
      sentAt: sentAt,
      safeError: safeError,
    );
  }

  final String operation;
  final String? reason;
  final WidgetUpdateSignalStatus status;
  final DateTime? sentAt;
  final String? safeError;

  bool get success => status == WidgetUpdateSignalStatus.success;
  bool get failed => status == WidgetUpdateSignalStatus.failed;
}
