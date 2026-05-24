import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/security/sensitive_data_policy.dart';
import 'package:quota_analytics/features/auth/domain/entities/web_auth_config.dart';
import 'package:quota_analytics/features/auth/domain/entities/web_auth_status.dart';

void main() {
  test('WebAuthConfig exposes default official WebView URLs', () {
    const config = WebAuthConfig();

    expect(config.loginUri.scheme, 'https');
    expect(config.loginUri.host, 'chatgpt.com');
    expect(config.loginUri.path, '/auth/login');
    expect(config.usageUri.scheme, 'https');
    expect(config.usageUri.host, 'chatgpt.com');
    expect(config.usageUri.path, '/codex/cloud/settings/analytics');
  });

  test('URL sanitizer removes query and fragment', () {
    final sanitized = SensitiveDataPolicy.sanitizeUrlForDisplay(
      'https://example.com/path/to/page?token=secret&state=abc#access_token=hidden',
    );

    expect(sanitized, 'https://example.com/path/to/page');
    expect(sanitized, isNot(contains('secret')));
    expect(sanitized, isNot(contains('access_token')));
    expect(sanitized, isNot(contains('?')));
    expect(sanitized, isNot(contains('#')));
  });

  test('navigation-based auth inference is conservative', () {
    const config = WebAuthConfig();

    expect(
      config.inferStatusFromNavigation(
        rawUrl: 'https://chatgpt.com/auth/login?next=/',
      ),
      WebAuthStatus.loggedOut,
    );
    expect(
      config.inferStatusFromNavigation(
        rawUrl: 'https://chatgpt.com/settings',
        title: 'Settings',
      ),
      WebAuthStatus.maybeLoggedIn,
    );
    expect(
      config.inferStatusFromNavigation(rawUrl: 'not a url'),
      WebAuthStatus.error,
    );
    expect(
      config.inferStatusFromNavigation(rawUrl: 'http://example.com'),
      WebAuthStatus.blocked,
    );
  });

  test('sensitive logging helper removes URL secrets', () {
    final sanitized = SensitiveDataPolicy.sanitizeLogText(
      'failed https://example.com/path?token=secret#refresh_token=hidden code=abc123',
    );

    expect(sanitized, contains('https://example.com/path'));
    expect(sanitized, isNot(contains('secret')));
    expect(sanitized, isNot(contains('hidden')));
    expect(sanitized, isNot(contains('#')));
    expect(sanitized, contains('code=<redacted>'));
  });
}
