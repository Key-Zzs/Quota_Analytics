import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/security/allowed_web_hosts.dart';

void main() {
  test('HTTPS allowed host is allowed', () {
    final decision = AllowedWebHosts.evaluate('https://chatgpt.com/settings');

    expect(decision.status, AllowedWebHostStatus.allowed);
    expect(decision.isAllowed, isTrue);
  });

  test('HTTP allowed host is blocked as non-HTTPS', () {
    final decision = AllowedWebHosts.evaluate('http://chatgpt.com/settings');

    expect(decision.status, AllowedWebHostStatus.blockedNonHttps);
  });

  test('unknown host is blocked', () {
    final decision = AllowedWebHosts.evaluate('https://example.com/');

    expect(decision.status, AllowedWebHostStatus.blockedUnknownHost);
  });

  test('empty URL fails safely', () {
    final decision = AllowedWebHosts.evaluate('');

    expect(decision.status, AllowedWebHostStatus.failed);
    expect(decision.sanitizedUrl, 'none');
  });
}
