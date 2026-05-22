class SensitiveDataPolicy {
  const SensitiveDataPolicy._();

  static const cookieReadingEnabled = false;
  static const tokenReadingEnabled = false;
  static const localStorageReadingEnabled = false;
  static const sessionStorageReadingEnabled = false;
  static const htmlExtractionEnabled = false;
  static const quotaParsingEnabled = false;
  static const backgroundRefreshEnabled = false;
  static const passwordStorageEnabled = false;
  static const webViewDataUploadEnabled = false;
  static const pageTextExtractionEnabled = true;

  static const stage3BoundaryNotice =
      'Stage 3: login container only. No quota extraction, no cookie/token access.';
  static const stage4BoundaryNotice =
      'Stage 4: user-triggered document.body.innerText extraction only.';

  static String sanitizeUrlForDisplay(String? rawUrl) {
    final value = rawUrl?.trim();
    if (value == null || value.isEmpty) {
      return 'none';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'invalid-url';
    }

    if (uri.scheme != 'https' && uri.scheme != 'http') {
      return '${uri.scheme}:';
    }

    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
    ).toString();
  }

  static String sanitizeLogText(String value) {
    final urlPattern = RegExp("https?://[^\\s<>\\\"']+");
    final withoutSensitiveUrls = value.replaceAllMapped(urlPattern, (match) {
      return sanitizeUrlForDisplay(match.group(0));
    });

    final keyValuePattern = RegExp(
      r'\b(access_token|refresh_token|session_token|id_token|token|secret|code)=([^&\s]+)',
      caseSensitive: false,
    );
    return withoutSensitiveUrls.replaceAllMapped(keyValuePattern, (match) {
      return '${match.group(1)}=<redacted>';
    });
  }
}
