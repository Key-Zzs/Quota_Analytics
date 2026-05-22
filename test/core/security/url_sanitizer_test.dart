import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/security/url_sanitizer.dart';

void main() {
  test('query is removed', () {
    expect(
      UrlSanitizer.sanitizeForDisplay('https://chatgpt.com/settings?token=abc'),
      'https://chatgpt.com/settings',
    );
  });

  test('fragment is removed', () {
    expect(
      UrlSanitizer.sanitizeForDisplay('https://chatgpt.com/#settings'),
      'https://chatgpt.com/',
    );
  });

  test('host and path are retained', () {
    expect(
      UrlSanitizer.sanitizeForDisplay('https://platform.openai.com/usage'),
      'https://platform.openai.com/usage',
    );
  });

  test('invalid URL does not crash', () {
    expect(UrlSanitizer.sanitizeForDisplay('not a url'), 'invalid-url');
  });
}
