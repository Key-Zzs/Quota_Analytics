enum AllowedWebHostStatus {
  allowed,
  blockedNonHttps,
  blockedUnknownHost,
  failed,
}

class AllowedWebHostDecision {
  const AllowedWebHostDecision({
    required this.status,
    required this.sanitizedUrl,
    required this.message,
  });

  final AllowedWebHostStatus status;
  final String sanitizedUrl;
  final String message;

  bool get isAllowed => status == AllowedWebHostStatus.allowed;
}

class AllowedWebHosts {
  const AllowedWebHosts._();

  static const hosts = <String>{
    'chatgpt.com',
    'chat.openai.com',
    'openai.com',
    'platform.openai.com',
  };

  static AllowedWebHostDecision evaluate(String? rawUrl) {
    final value = rawUrl?.trim();
    if (value == null || value.isEmpty) {
      return const AllowedWebHostDecision(
        status: AllowedWebHostStatus.failed,
        sanitizedUrl: 'none',
        message: 'Current WebView URL is empty.',
      );
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return const AllowedWebHostDecision(
        status: AllowedWebHostStatus.failed,
        sanitizedUrl: 'invalid-url',
        message: 'Current WebView URL is invalid.',
      );
    }

    final sanitizedUrl = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
    ).toString();

    if (uri.scheme != 'https') {
      return AllowedWebHostDecision(
        status: AllowedWebHostStatus.blockedNonHttps,
        sanitizedUrl: sanitizedUrl,
        message: 'Extraction is blocked because the current page is not HTTPS.',
      );
    }

    final host = uri.host.toLowerCase();
    if (!hosts.contains(host)) {
      return AllowedWebHostDecision(
        status: AllowedWebHostStatus.blockedUnknownHost,
        sanitizedUrl: sanitizedUrl,
        message:
            'Extraction is blocked because the current host is not allowlisted.',
      );
    }

    return AllowedWebHostDecision(
      status: AllowedWebHostStatus.allowed,
      sanitizedUrl: sanitizedUrl,
      message: 'Extraction is allowed for this HTTPS allowlisted host.',
    );
  }
}
