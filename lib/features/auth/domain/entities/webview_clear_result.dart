class WebViewClearResult {
  const WebViewClearResult({
    required this.cacheCleared,
    required this.localStorageCleared,
    required this.cookiesCleared,
    this.unsupportedOperations = const [],
  });

  final bool cacheCleared;
  final bool localStorageCleared;
  final bool cookiesCleared;
  final List<String> unsupportedOperations;

  bool get completed => cacheCleared && localStorageCleared && cookiesCleared;

  String get summary {
    if (completed && unsupportedOperations.isEmpty) {
      return 'WebView cache, local storage, and cookies were cleared for this app where supported.';
    }
    if (unsupportedOperations.isEmpty) {
      return 'WebView data clear completed with partial platform support.';
    }
    return 'WebView data clear completed; unsupported: ${unsupportedOperations.join(', ')}.';
  }
}
