import '../../../quota/domain/entities/parser_confidence.dart';

enum ManualRefreshSaveAction { autoSave, awaitConfirmation, blocked }

class ManualRefreshSaveDecision {
  const ManualRefreshSaveDecision({
    required this.action,
    required this.message,
  });

  final ManualRefreshSaveAction action;
  final String message;

  bool get shouldAutoSave => action == ManualRefreshSaveAction.autoSave;
  bool get canSaveManually =>
      action == ManualRefreshSaveAction.awaitConfirmation;
  bool get isBlocked => action == ManualRefreshSaveAction.blocked;
}

class ManualRefreshPolicy {
  const ManualRefreshPolicy({
    required this.autoSaveHighConfidence,
    required this.requireConfirmationForMediumConfidence,
    required this.allowLowConfidenceSave,
  });

  factory ManualRefreshPolicy.defaults() {
    return const ManualRefreshPolicy(
      autoSaveHighConfidence: false,
      requireConfirmationForMediumConfidence: true,
      allowLowConfidenceSave: false,
    );
  }

  final bool autoSaveHighConfidence;
  final bool requireConfirmationForMediumConfidence;
  final bool allowLowConfidenceSave;

  ManualRefreshSaveDecision decisionFor({
    required ParserConfidence confidence,
    required bool hasSnapshotCandidate,
    required bool parseSucceeded,
  }) {
    if (!parseSucceeded ||
        confidence == ParserConfidence.failed ||
        confidence == ParserConfidence.notApplicable) {
      return const ManualRefreshSaveDecision(
        action: ManualRefreshSaveAction.blocked,
        message: 'Failed parse results cannot be saved.',
      );
    }

    if (confidence == ParserConfidence.low) {
      if (allowLowConfidenceSave && hasSnapshotCandidate) {
        return const ManualRefreshSaveDecision(
          action: ManualRefreshSaveAction.awaitConfirmation,
          message: 'Low confidence save requires explicit confirmation.',
        );
      }
      return const ManualRefreshSaveDecision(
        action: ManualRefreshSaveAction.blocked,
        message: 'Low confidence results are not saved.',
      );
    }

    if (!hasSnapshotCandidate) {
      return const ManualRefreshSaveDecision(
        action: ManualRefreshSaveAction.blocked,
        message: 'No parsed snapshot candidate is available to save.',
      );
    }

    if (confidence == ParserConfidence.high && autoSaveHighConfidence) {
      return const ManualRefreshSaveDecision(
        action: ManualRefreshSaveAction.autoSave,
        message: 'High confidence result will be saved automatically.',
      );
    }

    if (confidence == ParserConfidence.medium) {
      return ManualRefreshSaveDecision(
        action: ManualRefreshSaveAction.awaitConfirmation,
        message: requireConfirmationForMediumConfidence
            ? 'Medium confidence results require confirmation before saving.'
            : 'Medium confidence results still require confirmation.',
      );
    }

    return const ManualRefreshSaveDecision(
      action: ManualRefreshSaveAction.awaitConfirmation,
      message: 'Review the parsed snapshot before saving.',
    );
  }

  ManualRefreshPolicy copyWith({
    bool? autoSaveHighConfidence,
    bool? requireConfirmationForMediumConfidence,
    bool? allowLowConfidenceSave,
  }) {
    return ManualRefreshPolicy(
      autoSaveHighConfidence:
          autoSaveHighConfidence ?? this.autoSaveHighConfidence,
      requireConfirmationForMediumConfidence:
          requireConfirmationForMediumConfidence ??
          this.requireConfirmationForMediumConfidence,
      allowLowConfidenceSave:
          allowLowConfidenceSave ?? this.allowLowConfidenceSave,
    );
  }
}
