class AppError implements Exception {
  const AppError(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return message;
    }
    return '$message ($cause)';
  }
}
