DateTime? dateTimeFromIso8601(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

String? dateTimeToIso8601(DateTime? value) {
  return value?.toIso8601String();
}
