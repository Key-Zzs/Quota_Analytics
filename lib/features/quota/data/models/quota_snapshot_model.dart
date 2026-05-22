import '../../../../core/serialization/date_time_converter.dart';
import '../../domain/entities/parser_confidence.dart';
import '../../domain/entities/quota_snapshot.dart';
import '../../domain/entities/quota_source.dart';
import '../../domain/entities/quota_window.dart';
import 'quota_window_model.dart';

class QuotaSnapshotModel extends QuotaSnapshot {
  const QuotaSnapshotModel({
    required super.id,
    required super.accountLabel,
    required super.source,
    required super.parserConfidence,
    required super.fiveHourWindow,
    required super.weeklyWindow,
    required super.creditsRemaining,
    required super.creditsTotal,
    required super.capturedAt,
    required super.nextSuggestedRefreshAt,
    required super.rawDebugText,
  });

  factory QuotaSnapshotModel.mock({
    required DateTime capturedAt,
    required int variant,
  }) {
    final fiveHourUsed = 58 + (variant % 7);
    final weeklyUsed = 742 + ((variant * 11) % 48);
    final creditsRemaining = 42.5 - (variant * 0.25);

    return QuotaSnapshotModel(
      id: 'mock-${capturedAt.microsecondsSinceEpoch}-$variant',
      accountLabel: 'Mock GPT Account',
      source: QuotaSource.mock,
      parserConfidence: ParserConfidence.high,
      fiveHourWindow: QuotaWindow.fromUsage(
        label: '5-hour window',
        used: fiveHourUsed,
        limit: 100,
        resetAt: capturedAt.add(const Duration(hours: 2, minutes: 35)),
      ),
      weeklyWindow: QuotaWindow.fromUsage(
        label: 'Weekly window',
        used: weeklyUsed,
        limit: 1000,
        resetAt: capturedAt.add(const Duration(days: 3, hours: 4)),
      ),
      creditsRemaining: creditsRemaining < 0 ? 0 : creditsRemaining,
      creditsTotal: 50,
      capturedAt: capturedAt,
      nextSuggestedRefreshAt: capturedAt.add(const Duration(minutes: 15)),
      rawDebugText:
          'Mock usage text only. Stage 2 does not read real account pages.',
    );
  }

  factory QuotaSnapshotModel.fromEntity(QuotaSnapshot snapshot) {
    return QuotaSnapshotModel(
      id: snapshot.id,
      accountLabel: snapshot.accountLabel,
      source: snapshot.source,
      parserConfidence: snapshot.parserConfidence,
      fiveHourWindow: QuotaWindowModel.fromEntity(snapshot.fiveHourWindow),
      weeklyWindow: QuotaWindowModel.fromEntity(snapshot.weeklyWindow),
      creditsRemaining: snapshot.creditsRemaining,
      creditsTotal: snapshot.creditsTotal,
      capturedAt: snapshot.capturedAt,
      nextSuggestedRefreshAt: snapshot.nextSuggestedRefreshAt,
      rawDebugText: snapshot.rawDebugText,
    );
  }

  factory QuotaSnapshotModel.fromJson(Map<String, Object?> json) {
    final capturedAt =
        dateTimeFromIso8601(json['capturedAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final fiveHourWindowJson = _readMap(json['fiveHourWindow']);
    final weeklyWindowJson = _readMap(json['weeklyWindow']);

    return QuotaSnapshotModel(
      id:
          _readString(json['id']) ??
          'snapshot-${capturedAt.microsecondsSinceEpoch}',
      accountLabel: _readString(json['accountLabel']) ?? 'Unknown account',
      source: quotaSourceFromStorageKey(_readString(json['source'])),
      parserConfidence: parserConfidenceFromStorageKey(
        _readString(json['parserConfidence']),
      ),
      fiveHourWindow: fiveHourWindowJson == null
          ? QuotaWindowModel.empty('5-hour window')
          : QuotaWindowModel.fromJson(
              fiveHourWindowJson,
              fallbackLabel: '5-hour window',
            ),
      weeklyWindow: weeklyWindowJson == null
          ? QuotaWindowModel.empty('Weekly window')
          : QuotaWindowModel.fromJson(
              weeklyWindowJson,
              fallbackLabel: 'Weekly window',
            ),
      creditsRemaining: _readDouble(json['creditsRemaining']),
      creditsTotal: _readDouble(json['creditsTotal']),
      capturedAt: capturedAt,
      nextSuggestedRefreshAt: dateTimeFromIso8601(
        json['nextSuggestedRefreshAt'],
      ),
      rawDebugText: _readString(json['rawDebugText']),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'accountLabel': accountLabel,
      'source': source.storageKey,
      'parserConfidence': parserConfidence.storageKey,
      'fiveHourWindow': QuotaWindowModel.fromEntity(fiveHourWindow).toJson(),
      'weeklyWindow': QuotaWindowModel.fromEntity(weeklyWindow).toJson(),
      'creditsRemaining': creditsRemaining,
      'creditsTotal': creditsTotal,
      'capturedAt': dateTimeToIso8601(capturedAt),
      'nextSuggestedRefreshAt': dateTimeToIso8601(nextSuggestedRefreshAt),
      'rawDebugText': rawDebugText,
    };
  }

  static String? _readString(Object? value) {
    return value is String ? value : null;
  }

  static double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  static Map<String, Object?>? _readMap(Object? value) {
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
    }
    return null;
  }
}
