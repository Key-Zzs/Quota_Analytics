class RedactionSummary {
  const RedactionSummary({
    required this.originalLength,
    required this.redactedLength,
    required this.redactedEmailCount,
    required this.redactedTokenCount,
    required this.redactedApiKeyCount,
    required this.redactedSecretCount,
    required this.truncated,
  });

  final int originalLength;
  final int redactedLength;
  final int redactedEmailCount;
  final int redactedTokenCount;
  final int redactedApiKeyCount;
  final int redactedSecretCount;
  final bool truncated;

  Map<String, Object?> toJson() {
    return {
      'originalLength': originalLength,
      'redactedLength': redactedLength,
      'redactedEmailCount': redactedEmailCount,
      'redactedTokenCount': redactedTokenCount,
      'redactedApiKeyCount': redactedApiKeyCount,
      'redactedSecretCount': redactedSecretCount,
      'truncated': truncated,
    };
  }
}

class RedactionResult {
  const RedactionResult({required this.text, required this.summary});

  final String text;
  final RedactionSummary summary;
}

class TextRedactor {
  const TextRedactor();

  static const debugPreviewMaxLength = 2000;
  static const persistedPreviewMaxLength = 2000;
  static const redactedTextMaxLength = 10000;

  RedactionResult redact(
    String input, {
    int maxLength = debugPreviewMaxLength,
  }) {
    var text = input;
    var redactedEmailCount = 0;
    var redactedTokenCount = 0;
    var redactedApiKeyCount = 0;
    var redactedSecretCount = 0;

    final emailResult = _replaceAllCounting(
      text,
      _emailPattern,
      (_) => '[REDACTED_EMAIL]',
    );
    text = emailResult.text;
    redactedEmailCount += emailResult.count;

    final bearerResult = _replaceAllCounting(
      text,
      _bearerPattern,
      (_) => 'Bearer [REDACTED_TOKEN]',
    );
    text = bearerResult.text;
    redactedTokenCount += bearerResult.count;

    final apiKeyResult = _replaceAllCounting(
      text,
      _apiKeyPattern,
      (_) => '[REDACTED_API_KEY]',
    );
    text = apiKeyResult.text;
    redactedApiKeyCount += apiKeyResult.count;
    redactedTokenCount += apiKeyResult.count;

    final secretResult = _replaceAllCounting(text, _secretValuePattern, (
      match,
    ) {
      final key = match.group(1) ?? 'secret';
      final separator = match.group(2) ?? ': ';
      return '$key$separator[REDACTED_SECRET]';
    });
    text = secretResult.text;
    redactedSecretCount += secretResult.count;
    redactedTokenCount += secretResult.count;

    final tokenResult = _replaceAllCounting(
      text,
      _longTokenPattern,
      (_) => '[REDACTED_TOKEN]',
    );
    text = tokenResult.text;
    redactedTokenCount += tokenResult.count;

    final redactedLength = text.length;
    final safeMaxLength = maxLength < 0 ? 0 : maxLength;
    final truncated = text.length > safeMaxLength;
    if (truncated) {
      text = text.substring(0, safeMaxLength);
    }

    return RedactionResult(
      text: text,
      summary: RedactionSummary(
        originalLength: input.length,
        redactedLength: redactedLength,
        redactedEmailCount: redactedEmailCount,
        redactedTokenCount: redactedTokenCount,
        redactedApiKeyCount: redactedApiKeyCount,
        redactedSecretCount: redactedSecretCount,
        truncated: truncated,
      ),
    );
  }

  _CountingReplacement _replaceAllCounting(
    String input,
    RegExp pattern,
    String Function(Match match) replacement,
  ) {
    var count = 0;
    final text = input.replaceAllMapped(pattern, (match) {
      count += 1;
      return replacement(match);
    });
    return _CountingReplacement(text: text, count: count);
  }

  static final _emailPattern = RegExp(
    r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
    caseSensitive: false,
  );

  static final _bearerPattern = RegExp(
    r'\bBearer\s+[A-Za-z0-9._~+/=-]{16,}',
    caseSensitive: false,
  );

  static final _apiKeyPattern = RegExp(r'\bsk-[A-Za-z0-9_-]{16,}\b');

  static final _secretValuePattern = RegExp(
    r'''\b((?:access|refresh|session)[_-]?token|access[_-]?key|session|secret|password|token)\b(\s*[:=]\s*|\s+)(["']?)[^\s,;&"'<>]{3,}''',
    caseSensitive: false,
  );

  static final _longTokenPattern = RegExp(
    r'(?<![A-Za-z0-9])(?=[A-Za-z0-9._~+/=-]{32,})(?=[A-Za-z0-9._~+/=-]*[A-Za-z])(?=[A-Za-z0-9._~+/=-]*\d)[A-Za-z0-9._~+/=-]{32,}(?![A-Za-z0-9])',
  );
}

class _CountingReplacement {
  const _CountingReplacement({required this.text, required this.count});

  final String text;
  final int count;
}
