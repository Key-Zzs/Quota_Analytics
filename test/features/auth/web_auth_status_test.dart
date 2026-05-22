import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/auth/domain/entities/web_auth_status.dart';

void main() {
  test('WebAuthStatus exposes stable labels', () {
    expect(WebAuthStatus.unknown.label, 'unknown');
    expect(WebAuthStatus.maybeLoggedIn.label, 'maybeLoggedIn');
    expect(WebAuthStatus.loggedOut.label, 'loggedOut');
    expect(WebAuthStatus.blocked.label, 'blocked');
    expect(WebAuthStatus.error.label, 'error');
  });

  test('maybeLoggedIn status remains explicitly conservative', () {
    expect(
      WebAuthStatus.maybeLoggedIn.description,
      contains('may be inaccurate'),
    );
  });
}
