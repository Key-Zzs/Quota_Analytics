import 'quota_window_type.dart';

class ParsedQuotaWindow {
  const ParsedQuotaWindow({
    required this.type,
    required this.used,
    required this.limit,
    required this.remaining,
    required this.remainingRatio,
    required this.resetAt,
    required this.resetText,
    required this.evidenceLabels,
  });

  final QuotaWindowType type;
  final int? used;
  final int? limit;
  final int? remaining;
  final double? remainingRatio;
  final DateTime? resetAt;
  final String? resetText;
  final List<String> evidenceLabels;

  bool get hasStructuredNumbers {
    return (used != null && limit != null) ||
        (remaining != null && limit != null) ||
        remainingRatio != null;
  }

  bool get hasAnySignal {
    return hasStructuredNumbers ||
        resetText != null ||
        evidenceLabels.isNotEmpty;
  }
}
