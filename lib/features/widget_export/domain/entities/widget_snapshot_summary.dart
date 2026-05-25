class WidgetSnapshotSummary {
  const WidgetSnapshotSummary({
    required this.schemaVersion,
    required this.id,
    required this.fiveHourRemainingRatio,
    required this.fiveHourResetText,
    required this.fiveHourResetAt,
    required this.weeklyRemainingRatio,
    required this.weeklyResetText,
    required this.weeklyResetAt,
    required this.creditsRemaining,
    required this.lastUpdatedAt,
    required this.source,
    required this.parserConfidence,
    required this.isStale,
    required this.staleReason,
    required this.displayTitle,
    required this.displaySubtitle,
    required this.statusLabel,
    required this.errorLabel,
    required this.exportedAt,
  });

  static const currentSchemaVersion = '1';

  final String schemaVersion;
  final String id;
  final double? fiveHourRemainingRatio;
  final String? fiveHourResetText;
  final DateTime? fiveHourResetAt;
  final double? weeklyRemainingRatio;
  final String? weeklyResetText;
  final DateTime? weeklyResetAt;
  final double? creditsRemaining;
  final DateTime? lastUpdatedAt;
  final String source;
  final String parserConfidence;
  final bool isStale;
  final String staleReason;
  final String displayTitle;
  final String displaySubtitle;
  final String? statusLabel;
  final String? errorLabel;
  final DateTime exportedAt;

  bool get hasQuotaData =>
      fiveHourRemainingRatio != null ||
      weeklyRemainingRatio != null ||
      creditsRemaining != null;
}
