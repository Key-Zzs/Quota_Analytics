enum ExtractionSource {
  webViewManual;

  String get label {
    return switch (this) {
      ExtractionSource.webViewManual => 'WebView manual',
    };
  }
}
