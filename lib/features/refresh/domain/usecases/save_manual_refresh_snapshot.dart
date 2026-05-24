import '../../../../core/security/sensitive_data_policy.dart';
import '../../../../core/time/clock.dart';
import '../../../quota/domain/entities/parser_confidence.dart';
import '../../../quota/domain/repositories/quota_repository.dart';
import '../entities/manual_refresh_policy.dart';
import '../entities/manual_refresh_result.dart';
import '../entities/manual_refresh_status.dart';
import '../repositories/manual_refresh_repository.dart';

class SaveManualRefreshSnapshot {
  const SaveManualRefreshSnapshot({
    required this.quotaRepository,
    required this.manualRefreshRepository,
    required this.clock,
  });

  final QuotaRepository quotaRepository;
  final ManualRefreshRepository manualRefreshRepository;
  final Clock clock;

  Future<ManualRefreshResult> call(
    ManualRefreshResult result, {
    required ManualRefreshPolicy policy,
  }) async {
    final decision = policy.decisionFor(
      confidence: result.parserConfidence,
      hasSnapshotCandidate: result.snapshotCandidate != null,
      parseSucceeded: result.parseResult?.success ?? false,
    );
    if (decision.isBlocked) {
      final blockedStatus = result.parserConfidence == ParserConfidence.low
          ? ManualRefreshStatus.lowConfidence
          : result.status;
      return _saveLast(
        result.copyWith(
          status: blockedStatus,
          errors: [...result.errors, decision.message],
          finishedAt: result.finishedAt ?? clock.now(),
        ),
      );
    }

    final candidate = result.snapshotCandidate;
    if (candidate == null) {
      return _saveLast(
        result.copyWith(
          errors: [...result.errors, 'No parsed snapshot candidate to save.'],
          finishedAt: result.finishedAt ?? clock.now(),
        ),
      );
    }

    try {
      final saved = await quotaRepository.saveSnapshot(candidate);
      return _saveLast(
        result.copyWith(
          status: ManualRefreshStatus.saved,
          snapshotCandidate: saved,
          savedSnapshotId: saved.id,
          finishedAt: clock.now(),
        ),
      );
    } on Object catch (error) {
      return _saveLast(
        result.copyWith(
          status: ManualRefreshStatus.failed,
          errors: [
            ...result.errors,
            'Local save failed: ${SensitiveDataPolicy.sanitizeLogText(error.toString())}',
          ],
          finishedAt: clock.now(),
        ),
      );
    }
  }

  Future<ManualRefreshResult> _saveLast(ManualRefreshResult result) {
    return manualRefreshRepository.saveLastResult(result);
  }
}
