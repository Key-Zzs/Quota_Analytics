import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/quota/domain/entities/parser_confidence.dart';
import 'package:quota_analytics/features/refresh/domain/entities/manual_refresh_policy.dart';

void main() {
  test('high confidence with auto-save off awaits confirmation', () {
    final decision = ManualRefreshPolicy.defaults().decisionFor(
      confidence: ParserConfidence.high,
      hasSnapshotCandidate: true,
      parseSucceeded: true,
    );

    expect(decision.action, ManualRefreshSaveAction.awaitConfirmation);
    expect(decision.canSaveManually, isTrue);
  });

  test('high confidence with auto-save on allows automatic save', () {
    final decision = ManualRefreshPolicy.defaults()
        .copyWith(autoSaveHighConfidence: true)
        .decisionFor(
          confidence: ParserConfidence.high,
          hasSnapshotCandidate: true,
          parseSucceeded: true,
        );

    expect(decision.action, ManualRefreshSaveAction.autoSave);
    expect(decision.shouldAutoSave, isTrue);
  });

  test('medium confidence requires confirmation', () {
    final decision = ManualRefreshPolicy.defaults().decisionFor(
      confidence: ParserConfidence.medium,
      hasSnapshotCandidate: true,
      parseSucceeded: true,
    );

    expect(decision.action, ManualRefreshSaveAction.awaitConfirmation);
    expect(decision.message, contains('confirmation'));
  });

  test('low confidence save is blocked by default', () {
    final decision = ManualRefreshPolicy.defaults().decisionFor(
      confidence: ParserConfidence.low,
      hasSnapshotCandidate: false,
      parseSucceeded: true,
    );

    expect(decision.action, ManualRefreshSaveAction.blocked);
    expect(decision.isBlocked, isTrue);
  });

  test('failed parse save is blocked', () {
    final decision = ManualRefreshPolicy.defaults().decisionFor(
      confidence: ParserConfidence.failed,
      hasSnapshotCandidate: false,
      parseSucceeded: false,
    );

    expect(decision.action, ManualRefreshSaveAction.blocked);
  });
}
