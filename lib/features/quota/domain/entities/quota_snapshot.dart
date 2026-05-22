import 'dart:convert';

import 'parser_confidence.dart';
import 'quota_source.dart';
import 'quota_window.dart';

class QuotaSnapshot {
  const QuotaSnapshot({
    required this.id,
    required this.accountLabel,
    required this.source,
    required this.parserConfidence,
    required this.fiveHourWindow,
    required this.weeklyWindow,
    required this.creditsRemaining,
    required this.creditsTotal,
    required this.capturedAt,
    required this.nextSuggestedRefreshAt,
    required this.rawDebugText,
  });

  final String id;
  final String accountLabel;
  final QuotaSource source;
  final ParserConfidence parserConfidence;
  final QuotaWindow fiveHourWindow;
  final QuotaWindow weeklyWindow;
  final double? creditsRemaining;
  final double? creditsTotal;
  final DateTime capturedAt;
  final DateTime? nextSuggestedRefreshAt;
  final String? rawDebugText;

  Map<String, Object?> toDebugMap() {
    return {
      'id': id,
      'accountLabel': accountLabel,
      'source': source.name,
      'parserConfidence': parserConfidence.name,
      'fiveHourWindow': fiveHourWindow.toDebugMap(),
      'weeklyWindow': weeklyWindow.toDebugMap(),
      'creditsRemaining': creditsRemaining,
      'creditsTotal': creditsTotal,
      'capturedAt': capturedAt.toIso8601String(),
      'nextSuggestedRefreshAt': nextSuggestedRefreshAt?.toIso8601String(),
      'rawDebugText': rawDebugText,
    };
  }

  String toDebugText() {
    return const JsonEncoder.withIndent('  ').convert(toDebugMap());
  }
}
