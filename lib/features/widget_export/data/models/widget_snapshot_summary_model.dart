import '../../../../core/serialization/date_time_converter.dart';
import '../../domain/entities/widget_snapshot_summary.dart';

class WidgetSnapshotSummaryModel extends WidgetSnapshotSummary {
  const WidgetSnapshotSummaryModel({
    required super.schemaVersion,
    required super.id,
    required super.fiveHourRemainingRatio,
    required super.fiveHourResetText,
    required super.fiveHourResetAt,
    required super.weeklyRemainingRatio,
    required super.weeklyResetText,
    required super.weeklyResetAt,
    required super.creditsRemaining,
    required super.lastUpdatedAt,
    required super.source,
    required super.parserConfidence,
    required super.isStale,
    required super.staleReason,
    required super.displayTitle,
    required super.displaySubtitle,
    required super.statusLabel,
    required super.errorLabel,
    required super.exportedAt,
  });

  factory WidgetSnapshotSummaryModel.fromEntity(WidgetSnapshotSummary summary) {
    return WidgetSnapshotSummaryModel(
      schemaVersion: summary.schemaVersion,
      id: summary.id,
      fiveHourRemainingRatio: summary.fiveHourRemainingRatio,
      fiveHourResetText: summary.fiveHourResetText,
      fiveHourResetAt: summary.fiveHourResetAt,
      weeklyRemainingRatio: summary.weeklyRemainingRatio,
      weeklyResetText: summary.weeklyResetText,
      weeklyResetAt: summary.weeklyResetAt,
      creditsRemaining: summary.creditsRemaining,
      lastUpdatedAt: summary.lastUpdatedAt,
      source: summary.source,
      parserConfidence: summary.parserConfidence,
      isStale: summary.isStale,
      staleReason: summary.staleReason,
      displayTitle: summary.displayTitle,
      displaySubtitle: summary.displaySubtitle,
      statusLabel: summary.statusLabel,
      errorLabel: summary.errorLabel,
      exportedAt: summary.exportedAt,
    );
  }

  factory WidgetSnapshotSummaryModel.fromJson(Map<String, Object?> json) {
    final exportedAt =
        dateTimeFromIso8601(json['exportedAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    return WidgetSnapshotSummaryModel(
      schemaVersion:
          _readString(json['schemaVersion']) ??
          WidgetSnapshotSummary.currentSchemaVersion,
      id: _readString(json['id']) ?? 'widget-summary-$exportedAt',
      fiveHourRemainingRatio: _readRatio(json['fiveHourRemainingRatio']),
      fiveHourResetText: _readString(json['fiveHourResetText']),
      fiveHourResetAt: dateTimeFromIso8601(json['fiveHourResetAt']),
      weeklyRemainingRatio: _readRatio(json['weeklyRemainingRatio']),
      weeklyResetText: _readString(json['weeklyResetText']),
      weeklyResetAt: dateTimeFromIso8601(json['weeklyResetAt']),
      creditsRemaining: _readDouble(json['creditsRemaining']),
      lastUpdatedAt: dateTimeFromIso8601(json['lastUpdatedAt']),
      source: _readString(json['source']) ?? 'unknown',
      parserConfidence: _readString(json['parserConfidence']) ?? 'unknown',
      isStale: _readBool(json['isStale']) ?? false,
      staleReason: _readString(json['staleReason']) ?? 'unknown',
      displayTitle: _readString(json['displayTitle']) ?? 'Quota Analytics',
      displaySubtitle: _readString(json['displaySubtitle']) ?? 'No quota data',
      statusLabel: _readString(json['statusLabel']),
      errorLabel: _readString(json['errorLabel']),
      exportedAt: exportedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'id': id,
      'fiveHourRemainingRatio': fiveHourRemainingRatio,
      'fiveHourResetText': fiveHourResetText,
      'fiveHourResetAt': dateTimeToIso8601(fiveHourResetAt),
      'weeklyRemainingRatio': weeklyRemainingRatio,
      'weeklyResetText': weeklyResetText,
      'weeklyResetAt': dateTimeToIso8601(weeklyResetAt),
      'creditsRemaining': creditsRemaining,
      'lastUpdatedAt': dateTimeToIso8601(lastUpdatedAt),
      'source': source,
      'parserConfidence': parserConfidence,
      'isStale': isStale,
      'staleReason': staleReason,
      'displayTitle': displayTitle,
      'displaySubtitle': displaySubtitle,
      'statusLabel': statusLabel,
      'errorLabel': errorLabel,
      'exportedAt': dateTimeToIso8601(exportedAt),
    };
  }

  static String? _readString(Object? value) {
    return value is String ? value : null;
  }

  static bool? _readBool(Object? value) {
    return value is bool ? value : null;
  }

  static double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  static double? _readRatio(Object? value) {
    final ratio = _readDouble(value);
    if (ratio == null) {
      return null;
    }
    if (ratio < 0) {
      return 0;
    }
    if (ratio > 1) {
      return 1;
    }
    return ratio;
  }
}
