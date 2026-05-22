import '../../../../core/parsing/text_lines.dart';
import '../../domain/entities/quota_window_type.dart';

class WindowLabelCandidate {
  const WindowLabelCandidate({
    required this.type,
    required this.line,
    required this.signal,
  });

  final QuotaWindowType type;
  final TextLine line;
  final String signal;
}

class QuotaCandidateExtractor {
  const QuotaCandidateExtractor();

  static final _fiveHourPattern = RegExp(
    r'(\b5\s*[- ]?\s*hours?\b|\b5h\b|\bfive\s+hours?\b|5\s*小时|五\s*小时)',
    caseSensitive: false,
  );
  static final _weeklyPattern = RegExp(
    r'(\bweekly\b|\bweek\b|\b7\s*[- ]?\s*days?\b|每周|周额度|周限制)',
    caseSensitive: false,
  );
  static final _windowContextPattern = RegExp(
    r'\b(quota|usage|limit|message|window|cap|remaining|left)\b|额度|限制|剩余|已使用',
    caseSensitive: false,
  );
  static final _resetOnlyPattern = RegExp(
    r'\b(?:reset|resets)\s+(?:in|at|on|tomorrow)\b|重置',
    caseSensitive: false,
  );

  List<WindowLabelCandidate> findWindowLabels(List<TextLine> lines) {
    final candidates = <WindowLabelCandidate>[];
    for (final line in lines) {
      if (_isFiveHourLabel(line.normalized)) {
        candidates.add(
          WindowLabelCandidate(
            type: QuotaWindowType.fiveHour,
            line: line,
            signal: 'five-hour window label',
          ),
        );
      }
      if (_weeklyPattern.hasMatch(line.normalized)) {
        candidates.add(
          WindowLabelCandidate(
            type: QuotaWindowType.weekly,
            line: line,
            signal: 'weekly window label',
          ),
        );
      }
    }
    return candidates;
  }

  bool _isFiveHourLabel(String normalized) {
    if (!_fiveHourPattern.hasMatch(normalized)) {
      return false;
    }
    final looksLikeResetDuration =
        _resetOnlyPattern.hasMatch(normalized) &&
        !_windowContextPattern.hasMatch(normalized);
    return !looksLikeResetDuration;
  }
}
