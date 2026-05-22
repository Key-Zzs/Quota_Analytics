import '../../../quota/data/models/quota_window_model.dart';
import '../../../quota/domain/entities/parser_confidence.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../../quota/domain/entities/quota_source.dart';
import '../../../quota/domain/entities/quota_window.dart';
import '../../domain/entities/quota_parse_result.dart';
import '../../domain/entities/quota_window_type.dart';

class ParseResultToQuotaSnapshotMapper {
  const ParseResultToQuotaSnapshotMapper();

  QuotaSnapshot? map(
    QuotaParseResult result, {
    String accountLabel = 'WebView Extracted Account',
  }) {
    if (!result.canCreateSnapshot) {
      return null;
    }

    final capturedAt = result.parsedAt;
    return QuotaSnapshot(
      id: 'parsed-${capturedAt.microsecondsSinceEpoch}',
      accountLabel: accountLabel,
      source: QuotaSource.webViewManualExtraction,
      parserConfidence: result.confidence,
      fiveHourWindow: _windowFor(result, QuotaWindowType.fiveHour),
      weeklyWindow: _windowFor(result, QuotaWindowType.weekly),
      creditsRemaining: result.credits?.remaining,
      creditsTotal: result.credits?.total,
      capturedAt: capturedAt,
      nextSuggestedRefreshAt: null,
      rawDebugText: _debugSummary(result),
    );
  }

  QuotaWindow _windowFor(QuotaParseResult result, QuotaWindowType type) {
    final matches = result.windows
        .where((window) => window.type == type)
        .toList(growable: false);
    final parsed = matches.isEmpty ? null : matches.first;
    if (parsed == null) {
      return QuotaWindowModel.empty(type.label);
    }
    return QuotaWindowModel(
      label: type.label,
      used: parsed.used,
      limit: parsed.limit,
      remaining: parsed.remaining,
      remainingRatio: parsed.remainingRatio,
      resetAt: parsed.resetAt,
      status: QuotaWindow.statusForRemainingRatio(parsed.remainingRatio),
    );
  }

  String _debugSummary(QuotaParseResult result) {
    final buffer = StringBuffer()
      ..writeln('Parser: ${result.parserVersion}')
      ..writeln('Confidence: ${result.confidence.label}')
      ..writeln('Matched signals: ${result.matchedSignals.join(', ')}');
    if (result.warnings.isNotEmpty) {
      buffer.writeln('Warnings: ${result.warnings.join(' | ')}');
    }
    if (result.errors.isNotEmpty) {
      buffer.writeln('Errors: ${result.errors.join(' | ')}');
    }
    for (final window in result.windows) {
      buffer.writeln(
        '${window.type.label} evidence: ${window.evidenceLabels.join(' | ')}',
      );
    }
    final creditsRawText = result.credits?.rawText;
    if (creditsRawText != null && creditsRawText.isNotEmpty) {
      buffer.writeln('Credits evidence: $creditsRawText');
    }

    final summary = buffer.toString().trim();
    if (summary.length <= 1200) {
      return summary;
    }
    return '${summary.substring(0, 1197)}...';
  }
}
