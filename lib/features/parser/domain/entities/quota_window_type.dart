enum QuotaWindowType { fiveHour, weekly, unknown }

extension QuotaWindowTypeLabel on QuotaWindowType {
  String get label {
    return switch (this) {
      QuotaWindowType.fiveHour => '5-hour window',
      QuotaWindowType.weekly => 'Weekly window',
      QuotaWindowType.unknown => 'Unknown window',
    };
  }
}
