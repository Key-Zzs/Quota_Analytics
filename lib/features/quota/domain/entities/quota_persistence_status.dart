class QuotaPersistenceStatus {
  const QuotaPersistenceStatus({
    required this.mode,
    required this.storageBackend,
    required this.lastSnapshotExists,
    required this.historyCount,
    required this.loadedFromLocalCache,
    required this.lastLoadTime,
    required this.lastSaveTime,
    required this.lastError,
  });

  factory QuotaPersistenceStatus.mockOnly() {
    return const QuotaPersistenceStatus(
      mode: 'mock-only memory',
      storageBackend: 'memory',
      lastSnapshotExists: false,
      historyCount: 0,
      loadedFromLocalCache: false,
      lastLoadTime: null,
      lastSaveTime: null,
      lastError: null,
    );
  }

  final String mode;
  final String storageBackend;
  final bool lastSnapshotExists;
  final int historyCount;
  final bool loadedFromLocalCache;
  final DateTime? lastLoadTime;
  final DateTime? lastSaveTime;
  final String? lastError;

  QuotaPersistenceStatus copyWith({
    String? mode,
    String? storageBackend,
    bool? lastSnapshotExists,
    int? historyCount,
    bool? loadedFromLocalCache,
    DateTime? lastLoadTime,
    DateTime? lastSaveTime,
    String? lastError,
    bool clearLastError = false,
  }) {
    return QuotaPersistenceStatus(
      mode: mode ?? this.mode,
      storageBackend: storageBackend ?? this.storageBackend,
      lastSnapshotExists: lastSnapshotExists ?? this.lastSnapshotExists,
      historyCount: historyCount ?? this.historyCount,
      loadedFromLocalCache: loadedFromLocalCache ?? this.loadedFromLocalCache,
      lastLoadTime: lastLoadTime ?? this.lastLoadTime,
      lastSaveTime: lastSaveTime ?? this.lastSaveTime,
      lastError: clearLastError ? null : lastError ?? this.lastError,
    );
  }
}
