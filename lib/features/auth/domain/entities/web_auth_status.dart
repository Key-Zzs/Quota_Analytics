enum WebAuthStatus {
  unknown,
  maybeLoggedIn,
  loggedOut,
  blocked,
  error;

  String get label {
    return switch (this) {
      WebAuthStatus.unknown => 'unknown',
      WebAuthStatus.maybeLoggedIn => 'maybeLoggedIn',
      WebAuthStatus.loggedOut => 'loggedOut',
      WebAuthStatus.blocked => 'blocked',
      WebAuthStatus.error => 'error',
    };
  }

  String get description {
    return switch (this) {
      WebAuthStatus.unknown => 'Navigation has not provided enough context.',
      WebAuthStatus.maybeLoggedIn =>
        'Navigation suggests a non-login page, but this may be inaccurate.',
      WebAuthStatus.loggedOut =>
        'Navigation still appears to be on a login or auth page.',
      WebAuthStatus.blocked => 'Navigation was blocked by the Stage 4 policy.',
      WebAuthStatus.error => 'The WebView reported a navigation or load error.',
    };
  }
}
