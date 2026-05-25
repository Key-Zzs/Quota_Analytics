class AppConstants {
  const AppConstants._();

  static const appName = 'Quota Analytics';
  static const appSubtitle =
      'Unofficial personal tool / safety-gated background reminders';
  static const appMode = 'stage8_2-quota-usage-refresh';
  static const stageNotice =
      'Stage 8.2: the Quota refresh action opens the visible Usage page, '
      'refreshes from the current page, and saves high-confidence manual '
      'results locally. Background checks remain notify-only unless a future '
      'background-safe data source exists.';
  static const safetyNotice =
      'No password storage, cookie/token/localStorage/sessionStorage reading, HTML extraction, network upload, hidden WebView scraping, or background page text extraction.';
}
