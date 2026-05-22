class UrlSanitizer {
  const UrlSanitizer._();

  static String sanitizeForDisplay(String? rawUrl) {
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
}
