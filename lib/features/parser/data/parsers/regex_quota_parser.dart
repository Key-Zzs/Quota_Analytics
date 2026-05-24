import '../../../../core/parsing/duration_patterns.dart';
import '../../../../core/parsing/number_patterns.dart';
import '../../../../core/parsing/text_lines.dart';
import '../../../quota/domain/entities/parser_confidence.dart';
import '../../domain/entities/parsed_credits.dart';
import '../../domain/entities/parsed_quota_window.dart';
import '../../domain/entities/quota_parse_result.dart';
import '../../domain/entities/quota_window_type.dart';
import '../../domain/repositories/quota_parser_repository.dart';
import 'quota_candidate_extractor.dart';
import 'quota_text_preprocessor.dart';

class RegexQuotaParser implements QuotaParser {
  RegexQuotaParser({
    this.preprocessor = const QuotaTextPreprocessor(),
    this.candidateExtractor = const QuotaCandidateExtractor(),
  });

  static const parserVersion = 'regex-quota-parser-v1';

  final QuotaTextPreprocessor preprocessor;
  final QuotaCandidateExtractor candidateExtractor;

  static final _weakSignalPattern = RegExp(
    r'\b(quota|usage|used|limit|remaining|left|reset|resets|credit|credits)\b|额度|已使用|剩余|重置|每周',
    caseSensitive: false,
  );
  static final _usageKeywordPattern = RegExp(
    r'\b(usage|used|limit|remaining|left|quota|cap|message|messages)\b|额度|已使用|剩余|限制',
    caseSensitive: false,
  );
  static final _creditKeywordPattern = RegExp(
    r'\b(credit|credits|balance)\b|点数|余额',
    caseSensitive: false,
  );

  @override
  QuotaParseResult parse(String text, {DateTime? now}) {
    final parsedAt = now ?? DateTime.now();
    final warnings = <String>[];
    final errors = <String>[];
    final matchedSignals = <String>{};

    if (text.trim().isEmpty) {
      return QuotaParseResult(
        success: false,
        confidence: ParserConfidence.failed,
        windows: const [],
        credits: null,
        matchedSignals: const [],
        warnings: const [],
        errors: const ['Parser input is empty.'],
        parsedAt: parsedAt,
        parserVersion: parserVersion,
      );
    }

    final document = preprocessor.preprocess(text);
    if (document.isEmpty) {
      return QuotaParseResult(
        success: false,
        confidence: ParserConfidence.failed,
        windows: const [],
        credits: null,
        matchedSignals: const [],
        warnings: const [],
        errors: const ['Parser input has no visible non-empty lines.'],
        parsedAt: parsedAt,
        parserVersion: parserVersion,
      );
    }

    _collectWeakSignals(document.normalizedText, matchedSignals);
    if (text.contains('[REDACTED_')) {
      matchedSignals.add('redacted marker present');
    }

    final labelCandidates = candidateExtractor.findWindowLabels(document.lines);
    for (final candidate in labelCandidates) {
      matchedSignals.add(candidate.signal);
    }

    final windows = <ParsedQuotaWindow>[];
    for (final type in [QuotaWindowType.fiveHour, QuotaWindowType.weekly]) {
      final typedCandidates = labelCandidates
          .where((candidate) => candidate.type == type)
          .toList(growable: false);
      if (typedCandidates.isEmpty) {
        continue;
      }
      final parsedWindow = _parseWindow(
        type: type,
        labelLine: typedCandidates.first.line,
        allLabelCandidates: labelCandidates,
        document: document,
        now: parsedAt,
        warnings: warnings,
        matchedSignals: matchedSignals,
      );
      if (parsedWindow.hasAnySignal) {
        windows.add(parsedWindow);
      }
    }

    final credits = _parseCredits(document.lines, matchedSignals);
    final confidence = _confidenceFor(
      document: document,
      windows: windows,
      credits: credits,
      warnings: warnings,
      matchedSignals: matchedSignals,
    );

    if (confidence == ParserConfidence.failed && errors.isEmpty) {
      errors.add('No structured quota signals were found.');
    }

    return QuotaParseResult(
      success:
          confidence != ParserConfidence.failed &&
          confidence != ParserConfidence.notApplicable,
      confidence: confidence,
      windows: windows,
      credits: credits,
      matchedSignals: matchedSignals.toList(growable: false)..sort(),
      warnings: warnings,
      errors: errors,
      parsedAt: parsedAt,
      parserVersion: parserVersion,
    );
  }

  ParsedQuotaWindow _parseWindow({
    required QuotaWindowType type,
    required TextLine labelLine,
    required List<WindowLabelCandidate> allLabelCandidates,
    required QuotaTextDocument document,
    required DateTime now,
    required List<String> warnings,
    required Set<String> matchedSignals,
  }) {
    final nearby = document
        .nearbyLines(labelLine.index, radius: 4)
        .where(
          (line) => _isCloserToThisWindow(
            line: line,
            type: type,
            labelLine: labelLine,
            allLabelCandidates: allLabelCandidates,
          ),
        )
        .toList(growable: false);
    final usageCandidates = <_NumericCandidate>[];
    final remainingCandidates = <_NumericCandidate>[];
    final percentCandidates = <_NumericCandidate>[];
    ResetTimeParseResult? reset;
    TextLine? resetLine;

    for (final line in nearby) {
      usageCandidates.addAll(
        _usageCandidates(line, labelLine.index, matchedSignals),
      );
      remainingCandidates.addAll(
        _remainingCandidates(line, labelLine.index, matchedSignals),
      );
      percentCandidates.addAll(
        _percentageCandidates(line, labelLine.index, matchedSignals),
      );
      percentCandidates.addAll(
        _nearbyPercentageCandidates(
          line,
          nearby,
          labelLine.index,
          matchedSignals,
        ),
      );

      final parsedReset = parseResetText(line.original, now);
      if (parsedReset != null) {
        matchedSignals.add('reset text');
        final currentDistance = resetLine == null
            ? 999
            : (resetLine.index - labelLine.index).abs();
        final nextDistance = (line.index - labelLine.index).abs();
        final preferLaterTie =
            nextDistance == currentDistance &&
            line.index >= labelLine.index &&
            (resetLine?.index ?? -1) < labelLine.index;
        if (reset == null || nextDistance < currentDistance || preferLaterTie) {
          reset = parsedReset;
          resetLine = line;
        }
      }
    }

    usageCandidates.sort((a, b) => b.score.compareTo(a.score));
    remainingCandidates.sort((a, b) => b.score.compareTo(a.score));
    percentCandidates.sort((a, b) => b.score.compareTo(a.score));

    _warnForConflicts(
      windowLabel: type.label,
      candidates: usageCandidates,
      valueLabel: 'used/limit',
      warnings: warnings,
    );
    _warnForConflicts(
      windowLabel: type.label,
      candidates: remainingCandidates,
      valueLabel: 'remaining/limit',
      warnings: warnings,
    );

    final accumulator = _WindowAccumulator();
    final evidence = <String>{_evidence(labelLine.original)};

    final usage = usageCandidates.isEmpty ? null : usageCandidates.first;
    if (usage != null) {
      accumulator.used = usage.used;
      accumulator.limit = usage.limit;
      evidence.add(_evidence(usage.line.original));
    }

    final remaining = remainingCandidates.isEmpty
        ? null
        : remainingCandidates.first;
    if (remaining != null) {
      evidence.add(_evidence(remaining.line.original));
      if (accumulator.limit != null &&
          remaining.limit != null &&
          accumulator.limit != remaining.limit) {
        warnings.add(
          '${type.label}: conflicting limits ${accumulator.limit} and ${remaining.limit}.',
        );
      } else {
        accumulator.limit ??= remaining.limit;
      }
      accumulator.remaining = remaining.remaining;
    }

    final percentage = percentCandidates.isEmpty
        ? null
        : percentCandidates.first;
    if (percentage != null) {
      evidence.add(_evidence(percentage.line.original));
      accumulator.remainingRatio ??= percentage.remainingRatio;
    }

    if (reset != null) {
      evidence.add(_evidence(reset.resetText));
    }

    _deriveMissingValues(type, accumulator, warnings);

    return ParsedQuotaWindow(
      type: type,
      used: accumulator.used,
      limit: accumulator.limit,
      remaining: accumulator.remaining,
      remainingRatio: accumulator.remainingRatio,
      resetAt: reset?.resetAt,
      resetText: reset?.resetText,
      evidenceLabels: evidence.toList(growable: false),
    );
  }

  bool _isCloserToThisWindow({
    required TextLine line,
    required QuotaWindowType type,
    required TextLine labelLine,
    required List<WindowLabelCandidate> allLabelCandidates,
  }) {
    final otherLabels =
        allLabelCandidates
            .where((candidate) => candidate.type != type)
            .map((candidate) => candidate.line.index)
            .toList(growable: false)
          ..sort();
    if (line.index >= labelLine.index) {
      final nextOtherLabel = otherLabels
          .where((index) => index > labelLine.index)
          .cast<int?>()
          .firstWhere((_) => true, orElse: () => null);
      if (nextOtherLabel == null || line.index < nextOtherLabel) {
        return true;
      }
    } else {
      final previousOtherLabels = otherLabels
          .where((index) => index < labelLine.index)
          .toList(growable: false);
      final previousOtherLabel = previousOtherLabels.isEmpty
          ? null
          : previousOtherLabels.last;
      if (previousOtherLabel != null && line.index > previousOtherLabel) {
        return false;
      }
    }

    final ownDistance = (line.index - labelLine.index).abs();
    final otherDistances = otherLabels
        .map((index) => (line.index - index).abs())
        .toList(growable: false);
    if (otherDistances.isEmpty) {
      return true;
    }
    otherDistances.sort();
    return ownDistance <= otherDistances.first;
  }

  List<_NumericCandidate> _usageCandidates(
    TextLine line,
    int labelIndex,
    Set<String> matchedSignals,
  ) {
    final candidates = <_NumericCandidate>[];
    final patterns = [
      RegExp(r'\b(\d{1,6})\s*/\s*(\d{1,6})\b'),
      RegExp(r'\b(?:used\s*)?(\d{1,6})\s+(?:of|out of)\s+(\d{1,6})\b'),
      RegExp(r'\b(\d{1,6})\s+used\s+(?:of|out of)\s+(\d{1,6})\b'),
      RegExp(r'已使用\s*(\d{1,6})\s*(?:/|of|共|总计)\s*(\d{1,6})'),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(line.normalized)) {
        final used = NumberPatterns.parseInt(match.group(1));
        final limit = NumberPatterns.parseInt(match.group(2));
        if (used == null || limit == null) {
          continue;
        }
        matchedSignals.add('used/limit pattern');
        candidates.add(
          _NumericCandidate(
            used: used,
            limit: limit,
            line: line,
            score: _scoreLine(line, labelIndex, baseScore: 70),
          ),
        );
      }
    }
    return candidates;
  }

  List<_NumericCandidate> _remainingCandidates(
    TextLine line,
    int labelIndex,
    Set<String> matchedSignals,
  ) {
    final candidates = <_NumericCandidate>[];
    final patterns = [
      RegExp(r'\b(\d{1,6})\s+(?:remaining|left)\s+(?:of|out of)\s+(\d{1,6})\b'),
      RegExp(r'\b(?:remaining|left)\s+(\d{1,6})\s+(?:of|out of)\s+(\d{1,6})\b'),
      RegExp(r'\b(\d{1,6})\s+(?:remaining|left)\b'),
      RegExp(r'\b(?:remaining|left)\s+(\d{1,6})\b'),
      RegExp(r'剩余\s*(\d{1,6})(?:\s*/\s*(\d{1,6}))?'),
      RegExp(r'(\d{1,6})\s*剩余(?:\s*/\s*(\d{1,6}))?'),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(line.normalized)) {
        final remaining = NumberPatterns.parseInt(match.group(1));
        final limit = match.groupCount >= 2
            ? NumberPatterns.parseInt(match.group(2))
            : null;
        if (remaining == null) {
          continue;
        }
        matchedSignals.add('remaining pattern');
        candidates.add(
          _NumericCandidate(
            remaining: remaining,
            limit: limit,
            line: line,
            score: _scoreLine(
              line,
              labelIndex,
              baseScore: limit == null ? 54 : 68,
            ),
          ),
        );
      }
    }
    return candidates;
  }

  List<_NumericCandidate> _percentageCandidates(
    TextLine line,
    int labelIndex,
    Set<String> matchedSignals,
  ) {
    final candidates = <_NumericCandidate>[];
    final trailing = RegExp(
      r'\b(\d{1,3}(?:\.\d{1,2})?)\s*%\s*(remaining|left|used)\b',
    );
    final leading = RegExp(
      r'\b(remaining|left|used)\s*(\d{1,3}(?:\.\d{1,2})?)\s*%',
    );

    for (final match in trailing.allMatches(line.normalized)) {
      final percent = NumberPatterns.parseDouble(match.group(1));
      final mode = match.group(2);
      final ratio = _ratioFromPercent(percent, mode);
      if (ratio == null) {
        continue;
      }
      matchedSignals.add('percentage pattern');
      candidates.add(
        _NumericCandidate(
          remainingRatio: ratio,
          line: line,
          score: _scoreLine(line, labelIndex, baseScore: 44),
        ),
      );
    }

    for (final match in leading.allMatches(line.normalized)) {
      final mode = match.group(1);
      final percent = NumberPatterns.parseDouble(match.group(2));
      final ratio = _ratioFromPercent(percent, mode);
      if (ratio == null) {
        continue;
      }
      matchedSignals.add('percentage pattern');
      candidates.add(
        _NumericCandidate(
          remainingRatio: ratio,
          line: line,
          score: _scoreLine(line, labelIndex, baseScore: 44),
        ),
      );
    }
    return candidates;
  }

  List<_NumericCandidate> _nearbyPercentageCandidates(
    TextLine line,
    List<TextLine> nearby,
    int labelIndex,
    Set<String> matchedSignals,
  ) {
    final percentMatch = RegExp(
      r'^\s*(\d{1,3}(?:\.\d{1,2})?)\s*%\s*$',
    ).firstMatch(line.normalized);
    if (percentMatch == null) {
      return const [];
    }

    final context = nearby
        .where((candidate) => (candidate.index - line.index).abs() <= 1)
        .map((candidate) => candidate.normalized)
        .join(' ');
    final isUsed = RegExp(
      r'\bused\b|已使用|使用中|已用',
      caseSensitive: false,
    ).hasMatch(context);
    final isRemaining = RegExp(
      r'\bremaining\b|\bleft\b|剩余',
      caseSensitive: false,
    ).hasMatch(context);
    if (!isUsed && !isRemaining) {
      return const [];
    }

    final percent = NumberPatterns.parseDouble(percentMatch.group(1));
    final ratio = _ratioFromPercent(percent, isUsed ? 'used' : 'remaining');
    if (ratio == null) {
      return const [];
    }

    matchedSignals.add('nearby percentage pattern');
    return [
      _NumericCandidate(
        remainingRatio: ratio,
        line: line,
        score: _scoreLine(line, labelIndex, baseScore: 46),
      ),
    ];
  }

  ParsedCredits? _parseCredits(
    List<TextLine> lines,
    Set<String> matchedSignals,
  ) {
    final candidates = <_CreditCandidate>[];
    for (final line in lines) {
      if (!_creditKeywordPattern.hasMatch(line.normalized)) {
        continue;
      }

      final patterns = [
        RegExp(
          r'\b(\d{1,6}(?:\.\d{1,4})?)\s*/\s*(\d{1,6}(?:\.\d{1,4})?)\s+credits?\b',
        ),
        RegExp(
          r'\b(\d{1,6}(?:\.\d{1,4})?)\s+(?:of|out of)\s+(\d{1,6}(?:\.\d{1,4})?)\s+credits?\b',
        ),
        RegExp(r'\b(\d{1,6}(?:\.\d{1,4})?)\s+credits?\s+(?:remaining|left)\b'),
        RegExp(
          r'\b(?:remaining\s+credits?|credit\s+balance|credits?\s+remaining)\D{0,12}(\d{1,6}(?:\.\d{1,4})?)\b',
        ),
        RegExp(r'\bcredits?\D{0,12}(\d{1,6}(?:\.\d{1,4})?)\b'),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(line.normalized);
        if (match == null) {
          continue;
        }
        final remaining = NumberPatterns.parseDouble(match.group(1));
        final total = match.groupCount >= 2
            ? NumberPatterns.parseDouble(match.group(2))
            : null;
        if (remaining == null) {
          continue;
        }
        matchedSignals.add('credits pattern');
        candidates.add(
          _CreditCandidate(
            remaining: remaining,
            total: total,
            rawText: _evidence(line.original),
            score: total == null ? 20 : 30,
          ),
        );
      }
    }

    if (candidates.isEmpty) {
      return null;
    }
    candidates.sort((a, b) => b.score.compareTo(a.score));
    final best = candidates.first;
    return ParsedCredits(
      remaining: best.remaining,
      total: best.total,
      rawText: best.rawText,
    );
  }

  void _deriveMissingValues(
    QuotaWindowType type,
    _WindowAccumulator accumulator,
    List<String> warnings,
  ) {
    final used = accumulator.used;
    final limit = accumulator.limit;
    final remaining = accumulator.remaining;

    if (used != null && limit != null && remaining == null) {
      accumulator.remaining = limit - used;
    }
    if (remaining != null && limit != null && used == null) {
      accumulator.used = limit - remaining;
    }
    if (accumulator.remainingRatio == null &&
        accumulator.remaining != null &&
        limit != null &&
        limit > 0) {
      accumulator.remainingRatio = accumulator.remaining! / limit;
    }

    if (used != null && limit != null && used > limit) {
      warnings.add('${type.label}: used value is greater than limit.');
    }
    if (accumulator.remaining != null &&
        limit != null &&
        accumulator.remaining! > limit) {
      warnings.add('${type.label}: remaining value is greater than limit.');
    }
    if (accumulator.remaining != null && accumulator.remaining! < 0) {
      warnings.add('${type.label}: remaining value is negative.');
    }
    final ratio = accumulator.remainingRatio;
    if (ratio != null && (ratio < 0 || ratio > 1)) {
      warnings.add('${type.label}: remaining ratio is outside 0..1.');
    }
  }

  void _warnForConflicts({
    required String windowLabel,
    required List<_NumericCandidate> candidates,
    required String valueLabel,
    required List<String> warnings,
  }) {
    if (candidates.length < 2) {
      return;
    }
    final first = candidates.first;
    final hasConflict = candidates.skip(1).any((candidate) {
      return _conflictsWith(first, candidate);
    });
    if (hasConflict) {
      warnings.add('$windowLabel: conflicting $valueLabel candidates found.');
    }
  }

  bool _conflictsWith(_NumericCandidate first, _NumericCandidate candidate) {
    return _valueConflicts(first.used, candidate.used) ||
        _valueConflicts(first.limit, candidate.limit) ||
        _valueConflicts(first.remaining, candidate.remaining) ||
        _doubleConflicts(first.remainingRatio, candidate.remainingRatio);
  }

  bool _valueConflicts(int? first, int? second) {
    if (first == null || second == null) {
      return false;
    }
    return first != second;
  }

  bool _doubleConflicts(double? first, double? second) {
    if (first == null || second == null) {
      return false;
    }
    return first != second;
  }

  ParserConfidence _confidenceFor({
    required QuotaTextDocument document,
    required List<ParsedQuotaWindow> windows,
    required ParsedCredits? credits,
    required List<String> warnings,
    required Set<String> matchedSignals,
  }) {
    final hasFiveHour = windows.any(
      (window) => window.type == QuotaWindowType.fiveHour,
    );
    final hasWeekly = windows.any(
      (window) => window.type == QuotaWindowType.weekly,
    );
    final structuredWindows = windows
        .where((window) => window.hasStructuredNumbers)
        .toList(growable: false);
    final hasConflict = warnings.any(
      (warning) => warning.toLowerCase().contains('conflicting'),
    );

    ParserConfidence confidence;
    if (hasFiveHour && hasWeekly && structuredWindows.isNotEmpty) {
      confidence = ParserConfidence.high;
    } else if (structuredWindows.isNotEmpty || credits?.hasValue == true) {
      confidence = ParserConfidence.medium;
    } else if (_weakSignalScore(document.normalizedText, matchedSignals) >= 2) {
      confidence = ParserConfidence.low;
    } else {
      confidence = ParserConfidence.failed;
    }

    if (hasConflict) {
      confidence = switch (confidence) {
        ParserConfidence.high => ParserConfidence.medium,
        ParserConfidence.medium => ParserConfidence.low,
        _ => confidence,
      };
    }
    return confidence;
  }

  int _scoreLine(TextLine line, int labelIndex, {required int baseScore}) {
    final proximity = (12 - ((line.index - labelIndex).abs() * 2)).clamp(0, 12);
    final keywordBonus = _usageKeywordPattern.hasMatch(line.normalized) ? 8 : 0;
    return baseScore + proximity + keywordBonus;
  }

  double? _ratioFromPercent(double? percent, String? mode) {
    if (percent == null || mode == null) {
      return null;
    }
    final bounded = percent / 100;
    if (mode == 'used') {
      return 1 - bounded;
    }
    return bounded;
  }

  void _collectWeakSignals(String normalizedText, Set<String> matchedSignals) {
    if (RegExp(
      r'\bquota\b|额度',
      caseSensitive: false,
    ).hasMatch(normalizedText)) {
      matchedSignals.add('quota keyword');
    }
    if (RegExp(
      r'\busage\b|已使用',
      caseSensitive: false,
    ).hasMatch(normalizedText)) {
      matchedSignals.add('usage keyword');
    }
    if (RegExp(
      r'\blimit\b|限制',
      caseSensitive: false,
    ).hasMatch(normalizedText)) {
      matchedSignals.add('limit keyword');
    }
    if (RegExp(
      r'\bremaining\b|\bleft\b|剩余',
      caseSensitive: false,
    ).hasMatch(normalizedText)) {
      matchedSignals.add('remaining keyword');
    }
    if (RegExp(
      r'\breset\b|\bresets\b|重置',
      caseSensitive: false,
    ).hasMatch(normalizedText)) {
      matchedSignals.add('reset keyword');
    }
    if (_creditKeywordPattern.hasMatch(normalizedText)) {
      matchedSignals.add('credits keyword');
    }
  }

  int _weakSignalScore(String normalizedText, Set<String> matchedSignals) {
    if (!_weakSignalPattern.hasMatch(normalizedText)) {
      return 0;
    }
    var score = 0;
    for (final signal in matchedSignals) {
      if (signal.contains('keyword') || signal.contains('label')) {
        score += 1;
      }
    }
    return score;
  }

  String _evidence(String value) {
    final trimmed = normalizeWhitespace(value);
    if (trimmed.length <= 120) {
      return trimmed;
    }
    return '${trimmed.substring(0, 117)}...';
  }
}

class _WindowAccumulator {
  int? used;
  int? limit;
  int? remaining;
  double? remainingRatio;
}

class _NumericCandidate {
  const _NumericCandidate({
    this.used,
    this.limit,
    this.remaining,
    this.remainingRatio,
    required this.line,
    required this.score,
  });

  final int? used;
  final int? limit;
  final int? remaining;
  final double? remainingRatio;
  final TextLine line;
  final int score;
}

class _CreditCandidate {
  const _CreditCandidate({
    required this.remaining,
    required this.total,
    required this.rawText,
    required this.score,
  });

  final double remaining;
  final double? total;
  final String rawText;
  final int score;
}
