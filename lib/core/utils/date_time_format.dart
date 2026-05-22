String formatDateTime(DateTime? value) {
  if (value == null) {
    return 'Unknown';
  }
  final local = value.toLocal();
  final date = '${local.year}-${_two(local.month)}-${_two(local.day)}';
  final time =
      '${_two(local.hour)}:${_two(local.minute)}:${_two(local.second)}';
  return '$date $time';
}

String formatDuration(Duration? value) {
  if (value == null) {
    return 'Not recorded';
  }
  if (value.inMilliseconds < 1000) {
    return '${value.inMilliseconds} ms';
  }
  return '${value.inSeconds}.${(value.inMilliseconds % 1000) ~/ 100}s';
}

String _two(int value) => value.toString().padLeft(2, '0');
