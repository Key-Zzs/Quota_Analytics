import '../../../../core/security/sensitive_data_policy.dart';

class WebAuthNavigationError {
  const WebAuthNavigationError({
    required this.description,
    this.errorCode,
    this.errorType,
  });

  final String description;
  final int? errorCode;
  final String? errorType;

  String get safeMessage {
    final buffer = StringBuffer();
    if (errorCode != null) {
      buffer.write('code $errorCode');
    }
    if (errorType != null && errorType!.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.write(' / ');
      }
      buffer.write(errorType);
    }
    if (description.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.write(': ');
      }
      buffer.write(SensitiveDataPolicy.sanitizeLogText(description));
    }
    return buffer.isEmpty ? 'Unknown WebView error' : buffer.toString();
  }
}
