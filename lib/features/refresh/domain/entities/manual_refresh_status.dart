enum ManualRefreshStatus {
  idle,
  checkingPage,
  extractingText,
  redactingText,
  parsing,
  awaitingUserConfirmation,
  saving,
  saved,
  blocked,
  extractionFailed,
  parseFailed,
  lowConfidence,
  failed;

  String get label {
    return switch (this) {
      ManualRefreshStatus.idle => 'idle',
      ManualRefreshStatus.checkingPage => 'checking page',
      ManualRefreshStatus.extractingText => 'extracting text',
      ManualRefreshStatus.redactingText => 'redacting text',
      ManualRefreshStatus.parsing => 'parsing',
      ManualRefreshStatus.awaitingUserConfirmation =>
        'awaiting user confirmation',
      ManualRefreshStatus.saving => 'saving',
      ManualRefreshStatus.saved => 'saved',
      ManualRefreshStatus.blocked => 'blocked',
      ManualRefreshStatus.extractionFailed => 'extraction failed',
      ManualRefreshStatus.parseFailed => 'parse failed',
      ManualRefreshStatus.lowConfidence => 'low confidence',
      ManualRefreshStatus.failed => 'failed',
    };
  }

  String get storageKey => name;

  bool get isActive {
    return switch (this) {
      ManualRefreshStatus.checkingPage ||
      ManualRefreshStatus.extractingText ||
      ManualRefreshStatus.redactingText ||
      ManualRefreshStatus.parsing ||
      ManualRefreshStatus.saving => true,
      _ => false,
    };
  }

  bool get isTerminal => !isActive && this != ManualRefreshStatus.idle;
}

ManualRefreshStatus manualRefreshStatusFromStorageKey(String? value) {
  return ManualRefreshStatus.values.firstWhere(
    (status) => status.storageKey == value,
    orElse: () => ManualRefreshStatus.idle,
  );
}
