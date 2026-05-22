enum ExtractionSafetyStatus {
  allowed,
  blockedNonHttps,
  blockedUnknownHost,
  failed;

  String get label {
    return switch (this) {
      ExtractionSafetyStatus.allowed => 'allowed',
      ExtractionSafetyStatus.blockedNonHttps => 'blockedNonHttps',
      ExtractionSafetyStatus.blockedUnknownHost => 'blockedUnknownHost',
      ExtractionSafetyStatus.failed => 'failed',
    };
  }

  bool get isSuccess => this == ExtractionSafetyStatus.allowed;
}
