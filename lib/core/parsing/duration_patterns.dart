class ResetTimeParseResult {
  const ResetTimeParseResult({required this.resetText, required this.resetAt});

  final String resetText;
  final DateTime? resetAt;
}

ResetTimeParseResult? parseResetText(String line, DateTime now) {
  final normalized = line.toLowerCase();
  final hasResetSignal =
      normalized.contains('reset') ||
      normalized.contains('resets') ||
      normalized.contains('重置');
  if (!hasResetSignal) {
    return null;
  }

  DateTime? resetAt;
  final compactHours = RegExp(
    r'\b(?:reset|resets)\s+in\s+(\d{1,3})\s*h(?:\s*(\d{1,2})\s*m)?\b',
  ).firstMatch(normalized);
  if (compactHours != null) {
    final hours = int.tryParse(compactHours.group(1) ?? '');
    final minutes = int.tryParse(compactHours.group(2) ?? '') ?? 0;
    if (hours != null) {
      resetAt = now.add(Duration(hours: hours, minutes: minutes));
    }
  }

  resetAt ??= _parseRelativeReset(normalized, now);

  return ResetTimeParseResult(resetText: line, resetAt: resetAt);
}

DateTime? _parseRelativeReset(String normalized, DateTime now) {
  final relative = RegExp(
    r'\b(?:reset|resets)\s+in\s+(\d{1,3})\s*(minutes?|mins?|m|hours?|hrs?|h|days?|d)\b',
  ).firstMatch(normalized);
  if (relative != null) {
    final value = int.tryParse(relative.group(1) ?? '');
    final unit = relative.group(2);
    if (value == null || unit == null) {
      return null;
    }
    if (unit.startsWith('m')) {
      return now.add(Duration(minutes: value));
    }
    if (unit.startsWith('h')) {
      return now.add(Duration(hours: value));
    }
    if (unit.startsWith('d')) {
      return now.add(Duration(days: value));
    }
  }

  if (RegExp(r'\b(?:reset|resets)\s+tomorrow\b').hasMatch(normalized)) {
    return now.add(const Duration(days: 1));
  }

  return null;
}
