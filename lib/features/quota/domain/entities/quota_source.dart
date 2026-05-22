enum QuotaSource {
  mock,
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
      QuotaSource.webViewPlaceholder => 'WebView placeholder',
      QuotaSource.officialApiPlaceholder => 'Official API placeholder',
      QuotaSource.browserExtensionPlaceholder =>
        'Browser extension placeholder',
      QuotaSource.desktopAgentPlaceholder => 'Desktop agent placeholder',
      QuotaSource.manualPlaceholder => 'Manual placeholder',
    };
  }
}
