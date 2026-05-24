import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/core/time/clock.dart';
import 'package:quota_analytics/features/extraction/domain/entities/extraction_safety_status.dart';
import 'package:quota_analytics/features/parser/domain/entities/parsed_quota_window.dart';
import 'package:quota_analytics/features/parser/domain/entities/quota_parse_result.dart';
import 'package:quota_analytics/features/parser/domain/entities/quota_window_type.dart';
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

void main() {
  final now = DateTime.utc(2026, 1, 1, 12);

  test('high confidence snapshot saves latest and history', () async {
    final quotaRepository = _FakeQuotaRepository();
    final manualRepository = _FakeManualRefreshRepository();
    final useCase = _useCase(quotaRepository, manualRepository, now);

    final result = await useCase(
      _result(now, ParserConfidence.high),
      policy: ManualRefreshPolicy.defaults(),
    );

    expect(result.status, ManualRefreshStatus.saved);
    expect(quotaRepository.latest, isNotNull);
    expect(quotaRepository.history.length, 1);
    expect(manualRepository.last?.savedSnapshotId, quotaRepository.latest?.id);
  });

  test(
    'medium confidence snapshot saves after explicit usecase call',
    () async {
      final quotaRepository = _FakeQuotaRepository();
      final useCase = _useCase(
        quotaRepository,
        _FakeManualRefreshRepository(),
        now,
      );

      final result = await useCase(
        _result(now, ParserConfidence.medium),
        policy: ManualRefreshPolicy.defaults(),
      );

      expect(result.status, ManualRefreshStatus.saved);
      expect(quotaRepository.history.length, 1);
    },
  );

  test('low confidence result is rejected by default policy', () async {
    final quotaRepository = _FakeQuotaRepository();
    final result =
        await _useCase(quotaRepository, _FakeManualRefreshRepository(), now)(
          _result(now, ParserConfidence.low, withCandidate: false),
          policy: ManualRefreshPolicy.defaults(),
        );

    expect(result.status, ManualRefreshStatus.lowConfidence);
    expect(result.errors.last, contains('Low confidence'));
    expect(quotaRepository.latest, isNull);
  });

  test('failed result is rejected by default policy', () async {
    final quotaRepository = _FakeQuotaRepository();
    final result =
        await _useCase(quotaRepository, _FakeManualRefreshRepository(), now)(
          _result(
            now,
            ParserConfidence.failed,
            withCandidate: false,
            parseSucceeded: false,
            status: ManualRefreshStatus.parseFailed,
          ),
          policy: ManualRefreshPolicy.defaults(),
        );

    expect(result.status, ManualRefreshStatus.parseFailed);
    expect(result.errors.last, contains('Failed parse'));
    expect(quotaRepository.latest, isNull);
  });
}

SaveManualRefreshSnapshot _useCase(
  _FakeQuotaRepository quotaRepository,
  _FakeManualRefreshRepository manualRepository,
  DateTime now,
) {
  return SaveManualRefreshSnapshot(
    quotaRepository: quotaRepository,
    manualRefreshRepository: manualRepository,
    clock: FixedClock(now),
  );
}

ManualRefreshResult _result(
  DateTime now,
  ParserConfidence confidence, {
  bool withCandidate = true,
  bool parseSucceeded = true,
  ManualRefreshStatus status = ManualRefreshStatus.awaitingUserConfirmation,
}) {
  final snapshot = QuotaSnapshotModel.mock(capturedAt: now, variant: 1);
  return ManualRefreshResult(
    status: status,
    safetyStatus: ExtractionSafetyStatus.allowed,
    parserConfidence: confidence,
    extractedPageText: null,
    parseResult: QuotaParseResult(
      success: parseSucceeded,
      confidence: confidence,
      windows: confidence == ParserConfidence.low
          ? const []
          : const [
              ParsedQuotaWindow(
                type: QuotaWindowType.fiveHour,
                used: 10,
                limit: 50,
                remaining: 40,
                remainingRatio: 0.8,
                resetAt: null,
                resetText: null,
                evidenceLabels: ['5-hour window'],
              ),
            ],
      credits: null,
      matchedSignals: const ['5-hour window'],
      warnings: const [],
      errors: const [],
      parsedAt: now,
      parserVersion: 'fake-parser',
    ),
    snapshotCandidate: withCandidate ? snapshot : null,
    redactionSummary: null,
    warnings: const [],
    errors: const [],
    startedAt: now,
    finishedAt: now,
    savedSnapshotId: null,
  );
}

class _FakeManualRefreshRepository implements ManualRefreshRepository {
  ManualRefreshResult? last;

  @override
  Future<void> clearLastResult() async {
    last = null;
  }

  @override
  Future<ManualRefreshResult?> getLastResult() async {
    return last;
  }

  @override
  Future<ManualRefreshResult> saveLastResult(ManualRefreshResult result) async {
    last = result;
    return result;
  }
}

class _FakeQuotaRepository implements QuotaRepository {
  QuotaSnapshot? latest;
  final List<QuotaSnapshot> history = [];

  @override
  Future<void> clearLocalQuotaData() async {
    latest = null;
    history.clear();
  }

  @override
  Future<List<QuotaSnapshot>> getHistory() async {
    return history;
  }

  @override
  Future<QuotaSnapshot> getLatestSnapshot() async {
    return latest!;
  }

  @override
  Future<QuotaPersistenceStatus> getPersistenceStatus() async {
    return QuotaPersistenceStatus.mockOnly();
  }

  @override
  Future<QuotaSnapshot> refreshSnapshot() async {
    return latest!;
  }

  @override
  Future<QuotaSnapshot> saveSnapshot(QuotaSnapshot snapshot) async {
    latest = snapshot;
    history.add(snapshot);
    return snapshot;
  }
}
