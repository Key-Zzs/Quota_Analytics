import '../../../../core/constants/web_constants.dart';
import 'web_auth_status.dart';

class WebAuthConfig {
  const WebAuthConfig({
    this.loginUrl = WebConstants.loginUrl,
    this.usageUrlPlaceholder = WebConstants.usageUrlPlaceholder,
  });

  final String loginUrl;
  final String usageUrlPlaceholder;

  Uri get loginUri => Uri.parse(loginUrl);
  Uri get usageUriPlaceholder => Uri.parse(usageUrlPlaceholder);

  bool isSupportedNavigationUrl(String? rawUrl) {
    final uri = _parseAbsoluteUri(rawUrl);
    if (uri == null) {
      return false;
    }
    return uri.scheme == 'https';
  }

  WebAuthStatus inferStatusFromNavigation({
    required String? rawUrl,
    String? title,
  }) {
    final uri = _parseAbsoluteUri(rawUrl);
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return WebAuthStatus.unknown;
    }
    if (uri == null) {
      return WebAuthStatus.error;
    }
    if (uri.scheme != 'https') {
      return WebAuthStatus.blocked;
    }

    if (_looksLikeLoginLocation(uri) || _looksLikeLoginTitle(title)) {
      return WebAuthStatus.loggedOut;
    }

    return WebAuthStatus.maybeLoggedIn;
  }

  Uri? _parseAbsoluteUri(String? rawUrl) {
    final value = rawUrl?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return null;
    }
    return uri;
  }

  bool _looksLikeLoginLocation(Uri uri) {
    final value = '${uri.host} ${uri.path} ${uri.fragment}'.toLowerCase();
    return _loginMarkers.any(value.contains);
  }

  bool _looksLikeLoginTitle(String? title) {
    final value = title?.trim().toLowerCase();
    if (value == null || value.isEmpty) {
      return false;
    }
    return _loginMarkers.any(value.contains);
  }

  static const _loginMarkers = [
    'login',
    'log in',
    'log-in',
    'signin',
    'sign in',
    'sign-in',
    'auth',
    'oauth',
  ];
}
