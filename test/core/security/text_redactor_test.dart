import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/security/text_redactor.dart';

void main() {
  const redactor = TextRedactor();

  test('email is replaced', () {
    final result = redactor.redact('Contact user@example.com');

    expect(result.text, 'Contact [REDACTED_EMAIL]');
    expect(result.summary.redactedEmailCount, 1);
  });

  test('sk-prefixed suspected API key is replaced', () {
    final result = redactor.redact('key sk-abcdefghijklmnopqrstuvwxyz123456');

    expect(result.text, 'key [REDACTED_API_KEY]');
    expect(result.summary.redactedApiKeyCount, 1);
    expect(result.summary.redactedTokenCount, 1);
  });

  test('Bearer token is replaced', () {
    final result = redactor.redact(
      'Authorization: Bearer abcdefghijklmnopqrstuvwxyz123456',
    );

    expect(result.text, 'Authorization: Bearer [REDACTED_TOKEN]');
    expect(result.summary.redactedTokenCount, 1);
  });

  test('access token query value is replaced', () {
    final result = redactor.redact('access_token=abcdef1234567890');

    expect(result.text, 'access_token=[REDACTED_SECRET]');
    expect(result.summary.redactedSecretCount, 1);
  });

  test('refresh token value is replaced', () {
    final result = redactor.redact('refresh_token: abcdef1234567890');

    expect(result.text, 'refresh_token: [REDACTED_SECRET]');
    expect(result.summary.redactedSecretCount, 1);
  });

  test('password value is replaced', () {
    final result = redactor.redact('password: hunter2');

    expect(result.text, 'password: [REDACTED_SECRET]');
    expect(result.summary.redactedSecretCount, 1);
  });

  test('long token-like string is replaced', () {
    final result = redactor.redact(
      'opaque abcdefghijklmnopqrstuvwxyz1234567890ABCDEFG',
    );

    expect(result.text, 'opaque [REDACTED_TOKEN]');
    expect(result.summary.redactedTokenCount, 1);
  });

  test('normal quota text is not over-redacted', () {
    final result = redactor.redact(
      '5-hour window remaining 12 of 80. Weekly window remaining 42 of 100.',
    );

    expect(result.text, contains('5-hour window remaining 12 of 80'));
    expect(result.text, contains('Weekly window remaining 42 of 100'));
    expect(result.summary.redactedTokenCount, 0);
  });

  test('output length limit is applied', () {
    final result = redactor.redact('abcdef', maxLength: 3);

    expect(result.text, 'abc');
    expect(result.summary.originalLength, 6);
    expect(result.summary.redactedLength, 6);
    expect(result.summary.truncated, isTrue);
  });

  test('redaction summary counts multiple categories', () {
    final result = redactor.redact(
      'user@example.com Bearer abcdefghijklmnop sk-abcdefghijklmnopqrstuvwxyz123456 password=secret',
    );

    expect(result.summary.originalLength, greaterThan(0));
    expect(result.summary.redactedLength, greaterThan(0));
    expect(result.summary.redactedEmailCount, 1);
    expect(result.summary.redactedApiKeyCount, 1);
    expect(result.summary.redactedSecretCount, 1);
    expect(result.summary.redactedTokenCount, 3);
  });
}
