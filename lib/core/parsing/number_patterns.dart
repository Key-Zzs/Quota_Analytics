class NumberPatterns {
  const NumberPatterns._();

  static const integer = r'(\d{1,6})';
  static const decimal = r'(\d{1,6}(?:\.\d{1,4})?)';

  static int? parseInt(String? value) {
    if (value == null) {
      return null;
    }
    return int.tryParse(value.replaceAll(',', ''));
  }

  static double? parseDouble(String? value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(value.replaceAll(',', ''));
  }
}
