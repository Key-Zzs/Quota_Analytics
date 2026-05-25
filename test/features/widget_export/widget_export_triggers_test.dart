import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_safety_status.dart';
import 'package:quota_analytics/features/parser/domain/entities/quota_parse_result.dart';
import 'package:quota_analytics/features/quota/data/models/quota_snapshot_model.dart';
import 'package:quota_analytics/features/quota/domain/entities/parser_confidence.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_persistence_status.dart';
import 'package:quota_analytics/features/quota/domain/entities/quota_snapshot.dart';
import 'package:quota_analytics/features/quota/domain/repositories/quota_repository.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_policy.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_result.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_status.dart';
import 'package:quota_analytics/features/refresh/domain/repositories/manual_refresh_repository.dart';
import 'package:quota_analytics/features/refresh/domain/usecases/save_manual_refresh_snapshot.dart';
import 'package:quota_analytics/features/widget_export/data/repositories/widget_exporting_quota_repository.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_export_metadata.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_export_result.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_export_status.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_snapshot_summary.dart';
import 'package:quota_analytics/features/widget_export/domain/repositories/widget_summary_repository.dart';

void main() {
  final now = DateTime.utc(2026, 5, 26, 10, 30);

  test('manual refresh save success triggers widget export', () async {
    final quotaRepository = _FakeQuotaRepository(_snapshot(now));
    final widgetRepository = _FakeWidgetSummaryRepository();
    final wrappedRepository = WidgetExportingQuotaRepository(
      delegate: quotaRepository,
      widgetRepository: widgetRepository,
    );
    final manualRepository = _FakeManualRefreshRepository();
    final usecase = SaveManualRefreshSnapshot(
      quotaRepository: wrappedRepository,
      manualRefreshRepository: manualRepository,
      clock: FixedClock(now),
    );

    final result = await usecase(
      _manualResult(_snapshot(now), now),
      policy: ManualRefreshPolicy.defaults().copyWith(
        autoSaveHighConfidence: true,
      ),
    );

    expect(result.status, ManualRefreshStatus.saved);
    expect(widgetRepository.exportedSnapshots, hasLength(1));
    expect(
      widgetRepository.exportedSnapshots.single.id,
      result.savedSnapshotId,
    );
  });

  test(
    'quota page Refresh usage page save success triggers widget export',
    () async {
      final widgetRepository = _FakeWidgetSummaryRepository();
      final repository = WidgetExportingQuotaRepository(
        delegate: _FakeQuotaRepository(_snapshot(now)),
        widgetRepository: widgetRepository,
      );

      final saved = await repository.saveSnapshot(_snapshot(now));

      expect(saved.id, _snapshot(now).id);
      expect(widgetRepository.exportedSnapshots, hasLength(1));
    },
  );

  test('foreground auto refresh save success triggers widget export', () async {
    final widgetRepository = _FakeWidgetSummaryRepository();
    final repository = WidgetExportingQuotaRepository(
      delegate: _FakeQuotaRepository(_snapshot(now)),
      widgetRepository: widgetRepository,
    );

    await repository.saveSnapshot(_snapshot(now));

    expect(widgetRepository.exportedSnapshots.single.id, _snapshot(now).id);
  });

  test('app startup local latest snapshot triggers widget export', () async {
    final widgetRepository = _FakeWidgetSummaryRepository();
    final repository = WidgetExportingQuotaRepository(
      delegate: _FakeQuotaRepository(
        _snapshot(now),
        persistenceStatus: _localCacheStatus(),
      ),
      widgetRepository: widgetRepository,
    );

    await repository.getLatestSnapshot();

    expect(widgetRepository.exportedSnapshots, hasLength(1));
  });

  test('app startup mock fallback does not export widget summary', () async {
    final widgetRepository = _FakeWidgetSummaryRepository();
    final repository = WidgetExportingQuotaRepository(
      delegate: _FakeQuotaRepository(_snapshot(now)),
      widgetRepository: widgetRepository,
    );

    await repository.getLatestSnapshot();

    expect(widgetRepository.exportedSnapshots, isEmpty);
  });

  test('clear local data clears widget summary', () async {
    final widgetRepository = _FakeWidgetSummaryRepository();
    final repository = WidgetExportingQuotaRepository(
      delegate: _FakeQuotaRepository(_snapshot(now)),
      widgetRepository: widgetRepository,
    );

    await repository.clearLocalQuotaData();

    expect(widgetRepository.clearCount, 1);
  });

  test('export failure does not fail quota snapshot save', () async {
    final repository = WidgetExportingQuotaRepository(
      delegate: _FakeQuotaRepository(_snapshot(now)),
      widgetRepository: _FakeWidgetSummaryRepository(throwOnExport: true),
    );

    final saved = await repository.saveSnapshot(_snapshot(now));

    expect(saved.id, _snapshot(now).id);
  });
}

QuotaSnapshot _snapshot(DateTime now) {
  return QuotaSnapshotModel.mock(capturedAt: now, variant: 3);
}

ManualRefreshResult _manualResult(QuotaSnapshot snapshot, DateTime now) {
  return ManualRefreshResult(
    status: ManualRefreshStatus.awaitingUserConfirmation,
    safetyStatus: ExtractionSafetyStatus.allowed,
    parserConfidence: ParserConfidence.high,
    extractedPageText: null,
    parseResult: QuotaParseResult(
      success: true,
      confidence: ParserConfidence.high,
      windows: const [],
      credits: null,
      matchedSignals: const [],
      warnings: const [],
      errors: const [],
      parsedAt: now,
      parserVersion: 'test-parser',
    ),
    snapshotCandidate: snapshot,
    redactionSummary: null,
    warnings: const [],
    errors: const [],
    startedAt: now,
    finishedAt: null,
    savedSnapshotId: null,
  );
}

QuotaPersistenceStatus _localCacheStatus() {
  return const QuotaPersistenceStatus(
    mode: 'local persistence',
    storageBackend: 'memory',
    lastSnapshotExists: true,
    historyCount: 1,
    loadedFromLocalCache: true,
    lastLoadTime: null,
    lastSaveTime: null,
    lastError: null,
  );
}

class _FakeQuotaRepository implements QuotaRepository {
  _FakeQuotaRepository(
    this.snapshot, {
    QuotaPersistenceStatus? persistenceStatus,
  }) : persistenceStatus =
           persistenceStatus ?? QuotaPersistenceStatus.mockOnly();

  QuotaSnapshot snapshot;
  QuotaPersistenceStatus persistenceStatus;
  bool cleared = false;

  @override
  Future<void> clearLocalQuotaData() async {
    cleared = true;
  }

  @override
  Future<List<QuotaSnapshot>> getHistory() async => [snapshot];

  @override
  Future<QuotaSnapshot> getLatestSnapshot() async => snapshot;

  @override
  Future<QuotaPersistenceStatus> getPersistenceStatus() async {
    return persistenceStatus;
  }

  @override
  Future<QuotaSnapshot> refreshSnapshot() async => snapshot;

  @override
  Future<QuotaSnapshot> saveSnapshot(QuotaSnapshot snapshot) async {
    this.snapshot = snapshot;
    return snapshot;
  }
}

class _FakeWidgetSummaryRepository implements WidgetSummaryRepository {
  _FakeWidgetSummaryRepository({this.throwOnExport = false});

  final bool throwOnExport;
  final List<QuotaSnapshot> exportedSnapshots = [];
  int clearCount = 0;

  @override
  Future<WidgetExportResult> clearSummary() async {
    clearCount += 1;
    return const WidgetExportResult(
      status: WidgetExportStatus.cleared,
      summary: null,
      exportedAt: null,
      safeError: null,
    );
  }

  @override
  Future<WidgetExportResult> exportSummary(QuotaSnapshot snapshot) async {
    if (throwOnExport) {
      throw StateError('widget write failed');
    }
    exportedSnapshots.add(snapshot);
    return const WidgetExportResult(
      status: WidgetExportStatus.success,
      summary: null,
      exportedAt: null,
      safeError: null,
    );
  }

  @override
  Future<WidgetSnapshotSummary?> getLatestSummary() async => null;

  @override
  Future<WidgetExportMetadata> getMetadata() async {
    return WidgetExportMetadata.initial();
  }
}

class _FakeManualRefreshRepository implements ManualRefreshRepository {
  ManualRefreshResult? result;

  @override
  Future<void> clearLastResult() async {
    result = null;
  }

  @override
  Future<ManualRefreshResult?> getLastResult() async => result;

  @override
  Future<ManualRefreshResult> saveLastResult(ManualRefreshResult result) async {
    this.result = result;
    return result;
  }
}
