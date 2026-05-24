class RefreshFailureMetadata {
  const RefreshFailureMetadata({
    required this.failed,
    required this.occurredAt,
    required this.statusLabel,
  });

  static const none = RefreshFailureMetadata(
    failed: false,
    occurredAt: null,
    statusLabel: 'none',
  );

  final bool failed;
  final DateTime? occurredAt;
  final String statusLabel;
}
