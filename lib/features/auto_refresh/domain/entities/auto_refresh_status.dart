enum AutoRefreshStatus {
  disabled('disabled'),
  idle('idle'),
  waitingForInterval('waiting for interval'),
  checkingEligibility('checking eligibility'),
  refreshing('refreshing'),
  skippedNoWebView('skipped: no WebView'),
  skippedPageLoading('skipped: page loading'),
  skippedUnsafeUrl('skipped: unsafe URL'),
  skippedIntervalNotReached('skipped: interval not reached'),
  skippedRefreshInProgress('skipped: refresh in progress'),
  skippedNotForeground('skipped: not foreground'),
  success('success'),
  failed('failed'),
  cooldown('cooldown');

  const AutoRefreshStatus(this.label);

  final String label;

  bool get isSkipped {
    return switch (this) {
      AutoRefreshStatus.skippedNoWebView ||
      AutoRefreshStatus.skippedPageLoading ||
      AutoRefreshStatus.skippedUnsafeUrl ||
      AutoRefreshStatus.skippedIntervalNotReached ||
      AutoRefreshStatus.skippedRefreshInProgress ||
      AutoRefreshStatus.skippedNotForeground => true,
      _ => false,
    };
  }
}
