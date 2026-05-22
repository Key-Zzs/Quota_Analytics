import 'dart:convert';

import '../../../../core/storage/json_storage.dart';
import '../../../../core/storage/local_storage_keys.dart';
import '../../../../core/time/clock.dart';
import '../../domain/entities/quota_persistence_status.dart';
import '../../domain/entities/quota_snapshot.dart';
import '../models/quota_snapshot_model.dart';

class LocalQuotaDataSource {
  LocalQuotaDataSource({
    required this.storage,
    required this.clock,
    this.historyLimit = 100,
  }) : _status = QuotaPersistenceStatus(
         mode: 'local persistence',
         storageBackend: storage.backendName,
         lastSnapshotExists: false,
         historyCount: 0,
         loadedFromLocalCache: false,
         lastLoadTime: null,
         lastSaveTime: null,
         lastError: null,
       );

  final JsonStorage storage;
  final Clock clock;
  final int historyLimit;

  QuotaPersistenceStatus _status;

  Future<QuotaSnapshotModel?> loadLatestSnapshot() async {
    _status = _status.copyWith(lastLoadTime: clock.now(), clearLastError: true);
    final raw = await storage.readString(LocalStorageKeys.quotaLatestSnapshot);
    if (raw == null) {
      _status = _status.copyWith(
        lastSnapshotExists: false,
        loadedFromLocalCache: false,
      );
      return null;
    }

    try {
      final snapshot = _decodeSnapshot(raw);
      _status = _status.copyWith(
        lastSnapshotExists: true,
        loadedFromLocalCache: true,
        clearLastError: true,
      );
      return snapshot;
    } on Object catch (error) {
      await storage.remove(LocalStorageKeys.quotaLatestSnapshot);
      _status = _status.copyWith(
        lastSnapshotExists: false,
        loadedFromLocalCache: false,
        lastError: 'Failed to read latest snapshot: $error',
      );
      return null;
    }
  }

  Future<void> saveLatestSnapshot(QuotaSnapshot snapshot) async {
    try {
      final model = QuotaSnapshotModel.fromEntity(snapshot);
      await storage.writeString(
        LocalStorageKeys.quotaLatestSnapshot,
        jsonEncode(model.toJson()),
      );
      _status = _status.copyWith(
        lastSnapshotExists: true,
        loadedFromLocalCache: false,
        lastSaveTime: clock.now(),
        clearLastError: true,
      );
    } on Object catch (error) {
      _status = _status.copyWith(
        lastSaveTime: clock.now(),
        lastError: 'Failed to save latest snapshot: $error',
      );
      rethrow;
    }
  }

  Future<List<QuotaSnapshotModel>> loadHistory() {
    return _loadHistory(recordLoad: true);
  }

  Future<void> appendHistory(QuotaSnapshot snapshot) async {
    try {
      final history = List<QuotaSnapshotModel>.of(
        await _loadHistory(recordLoad: false),
      );
      history.insert(0, QuotaSnapshotModel.fromEntity(snapshot));
      history.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
      final trimmed = history.take(historyLimit).toList(growable: false);

      await storage.writeString(
        LocalStorageKeys.quotaSnapshotHistory,
        jsonEncode(trimmed.map((snapshot) => snapshot.toJson()).toList()),
      );
      _status = _status.copyWith(
        historyCount: trimmed.length,
        lastSaveTime: clock.now(),
        clearLastError: true,
      );
    } on Object catch (error) {
      _status = _status.copyWith(
        lastSaveTime: clock.now(),
        lastError: 'Failed to append snapshot history: $error',
      );
      rethrow;
    }
  }

  Future<void> clearAll() async {
    await storage.remove(LocalStorageKeys.quotaLatestSnapshot);
    await storage.remove(LocalStorageKeys.quotaSnapshotHistory);
    _status = _status.copyWith(
      lastSnapshotExists: false,
      historyCount: 0,
      loadedFromLocalCache: false,
      lastSaveTime: clock.now(),
      clearLastError: true,
    );
  }

  Future<QuotaPersistenceStatus> inspect() async {
    final latest = await storage.readString(
      LocalStorageKeys.quotaLatestSnapshot,
    );
    final history = await _loadHistory(recordLoad: false);
    _status = _status.copyWith(
      lastSnapshotExists: latest != null,
      historyCount: history.length,
    );
    return _status;
  }

  Future<List<QuotaSnapshotModel>> _loadHistory({
    required bool recordLoad,
  }) async {
    if (recordLoad) {
      _status = _status.copyWith(
        lastLoadTime: clock.now(),
        clearLastError: true,
      );
    }

    final raw = await storage.readString(LocalStorageKeys.quotaSnapshotHistory);
    if (raw == null) {
      _status = _status.copyWith(historyCount: 0);
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('history root is not a JSON list');
      }

      var skipped = 0;
      final history = <QuotaSnapshotModel>[];
      for (final item in decoded) {
        try {
          if (item is! Map) {
            throw const FormatException('history item is not a JSON object');
          }
          history.add(
            QuotaSnapshotModel.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        } on Object {
          skipped += 1;
        }
      }

      history.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
      final trimmed = history.take(historyLimit).toList(growable: false);
      _status = _status.copyWith(
        historyCount: trimmed.length,
        lastError: skipped == 0
            ? null
            : 'Skipped $skipped corrupted history item(s).',
        clearLastError: skipped == 0,
      );
      return trimmed;
    } on Object catch (error) {
      await storage.remove(LocalStorageKeys.quotaSnapshotHistory);
      _status = _status.copyWith(
        historyCount: 0,
        lastError: 'Failed to read snapshot history: $error',
      );
      return const [];
    }
  }

  QuotaSnapshotModel _decodeSnapshot(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('latest snapshot root is not a JSON object');
    }
    return QuotaSnapshotModel.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}
