class AppConstants {
  const AppConstants._();

  static const appName = 'Quota Analytics';
  static const appSubtitle =
      'Unofficial personal tool / safety-gated background reminders';
  static const appMode = 'stage9-widget-data-export';
  static const stageNotice =
      'Stage 9: latest quota snapshots are exported as a safe widget summary. '
      'Android home screen widget UI is planned for Stage 10. Background '
      'checks remain notify-only unless a future background-safe data source '
      'exists.';
  static const safetyNotice =
      'No password storage, cookie/token/localStorage/sessionStorage reading, HTML extraction, network upload, hidden WebView scraping, or background page text extraction.';
}
