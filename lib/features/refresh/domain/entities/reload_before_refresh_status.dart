enum ReloadBeforeRefreshStatus {
  disabled,
  idle,
  checkingUrl,
  blockedUnsafeUrl,
  blockedNoWebView,
  blockedPageLoading,
  blockedAlreadyRefreshing,
  blockedCooldown,
  reloading,
  waitingForPageFinished,
  waitingForSettleDelay,
  readyForExtraction,
  loginRequired,
  timeout,
  cancelled,
  failed,
  completed;

  String get label {
    return switch (this) {
      ReloadBeforeRefreshStatus.disabled => 'disabled',
      ReloadBeforeRefreshStatus.idle => 'idle',
      ReloadBeforeRefreshStatus.checkingUrl => 'checkingUrl',
      ReloadBeforeRefreshStatus.blockedUnsafeUrl => 'blockedUnsafeUrl',
      ReloadBeforeRefreshStatus.blockedNoWebView => 'blockedNoWebView',
      ReloadBeforeRefreshStatus.blockedPageLoading => 'blockedPageLoading',
      ReloadBeforeRefreshStatus.blockedAlreadyRefreshing =>
        'blockedAlreadyRefreshing',
      ReloadBeforeRefreshStatus.blockedCooldown => 'blockedCooldown',
      ReloadBeforeRefreshStatus.reloading => 'reloading',
      ReloadBeforeRefreshStatus.waitingForPageFinished =>
        'waitingForPageFinished',
      ReloadBeforeRefreshStatus.waitingForSettleDelay =>
        'waitingForSettleDelay',
      ReloadBeforeRefreshStatus.readyForExtraction => 'readyForExtraction',
      ReloadBeforeRefreshStatus.loginRequired => 'loginRequired',
      ReloadBeforeRefreshStatus.timeout => 'timeout',
      ReloadBeforeRefreshStatus.cancelled => 'cancelled',
      ReloadBeforeRefreshStatus.failed => 'failed',
      ReloadBeforeRefreshStatus.completed => 'completed',
    };
  }

  bool get allowsExtraction {
    return this == ReloadBeforeRefreshStatus.readyForExtraction ||
        this == ReloadBeforeRefreshStatus.completed;
  }

  bool get isTerminal {
    return switch (this) {
      ReloadBeforeRefreshStatus.checkingUrl ||
      ReloadBeforeRefreshStatus.reloading ||
      ReloadBeforeRefreshStatus.waitingForPageFinished ||
      ReloadBeforeRefreshStatus.waitingForSettleDelay ||
      ReloadBeforeRefreshStatus.readyForExtraction => false,
      _ => true,
    };
  }
}

ReloadBeforeRefreshStatus reloadBeforeRefreshStatusFromStorageKey(
  String? value,
) {
  return ReloadBeforeRefreshStatus.values.firstWhere(
    (status) => status.name == value || status.label == value,
    orElse: () => ReloadBeforeRefreshStatus.idle,
  );
}
