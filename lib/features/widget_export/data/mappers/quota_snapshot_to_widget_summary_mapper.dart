import '../../../../core/time/clock.dart';
import '../../../quota/domain/entities/parser_confidence.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../../quota/domain/entities/quota_source.dart';
import '../../../quota/domain/entities/quota_window.dart';
import '../../domain/entities/widget_snapshot_summary.dart';
import '../models/widget_snapshot_summary_model.dart';

class QuotaSnapshotToWidgetSummaryMapper {
  const QuotaSnapshotToWidgetSummaryMapper({
    this.staleThreshold = const Duration(minutes: 30),
  });

  final Duration staleThreshold;

  WidgetSnapshotSummary map(QuotaSnapshot snapshot, {required Clock clock}) {
    final now = clock.now();
    final lastUpdatedAt = snapshot.capturedAt;
    final age = now.difference(lastUpdatedAt);
    final isStale = age > staleThreshold;
    final fiveHourRatio = _clampRatio(snapshot.fiveHourWindow.remainingRatio);
    final weeklyRatio = _clampRatio(snapshot.weeklyWindow.remainingRatio);
    final statusLabel = _statusLabel(
      isStale: isStale,
      fiveHourRatio: fiveHourRatio,
      weeklyRatio: weeklyRatio,
    );

    return WidgetSnapshotSummaryModel(
      schemaVersion: WidgetSnapshotSummary.currentSchemaVersion,
      id: snapshot.id,
      fiveHourRemainingRatio: fiveHourRatio,
      fiveHourResetText: _resetText(snapshot.fiveHourWindow),
      fiveHourResetAt: snapshot.fiveHourWindow.resetAt,
      weeklyRemainingRatio: weeklyRatio,
      weeklyResetText: _resetText(snapshot.weeklyWindow),
      weeklyResetAt: snapshot.weeklyWindow.resetAt,
      creditsRemaining: snapshot.creditsRemaining,
      lastUpdatedAt: lastUpdatedAt,
      source: snapshot.source.storageKey,
      parserConfidence: snapshot.parserConfidence.storageKey,
      isStale: isStale,
      staleReason: isStale ? 'stale_by_age' : 'fresh',
      displayTitle: 'Quota Analytics',
      displaySubtitle: isStale ? 'Stale data' : _updatedSubtitle(lastUpdatedAt),
      statusLabel: statusLabel,
      errorLabel: _errorLabel(
        fiveHourRatio: fiveHourRatio,
        weeklyRatio: weeklyRatio,
      ),
      exportedAt: now,
    );
  }

  String _resetText(QuotaWindow window) {
    if (window.resetAt == null) {
      return 'Reset time unknown';
    }
    return 'Reset time available';
  }

  String _updatedSubtitle(DateTime lastUpdatedAt) {
    final local = lastUpdatedAt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return 'Updated $hour:$minute';
  }

  String _statusLabel({
    required bool isStale,
    required double? fiveHourRatio,
    required double? weeklyRatio,
  }) {
    if (isStale) {
      return 'STALE';
    }
    final ratios = [?fiveHourRatio, ?weeklyRatio];
    if (ratios.isEmpty) {
      return 'UNKNOWN';
    }
    if (ratios.any((ratio) => ratio <= 0.25)) {
      return 'LOW';
    }
    return 'OK';
  }

  String? _errorLabel({
    required double? fiveHourRatio,
    required double? weeklyRatio,
  }) {
    if (fiveHourRatio == null && weeklyRatio == null) {
      return 'No data';
    }
    return null;
  }

  double? _clampRatio(double? ratio) {
    if (ratio == null) {
      return null;
    }
    if (ratio < 0) {
      return 0;
    }
    if (ratio > 1) {
      return 1;
    }
    return ratio;
  }
}
