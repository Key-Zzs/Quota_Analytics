enum QuotaSource {
  mock,
  webViewManualExtraction,
  webViewPlaceholder,
  officialApiPlaceholder,
  browserExtensionPlaceholder,
  desktopAgentPlaceholder,
  manualPlaceholder,
}

extension QuotaSourceLabel on QuotaSource {
  String get label {
    return switch (this) {
      QuotaSource.mock => 'mock',
      QuotaSource.webViewManualExtraction => 'WebView manual extraction',
      QuotaSource.webViewPlaceholder => 'WebView placeholder',
      QuotaSource.officialApiPlaceholder => 'Official API placeholder',
      QuotaSource.browserExtensionPlaceholder =>
        'Browser extension placeholder',
      QuotaSource.desktopAgentPlaceholder => 'Desktop agent placeholder',
      QuotaSource.manualPlaceholder => 'Manual placeholder',
    };
  }

  String get storageKey => name;
}

QuotaSource quotaSourceFromStorageKey(String? value) {
  return QuotaSource.values.firstWhere(
    (source) => source.storageKey == value,
    orElse: () => QuotaSource.mock,
  );
}
