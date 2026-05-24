import '../../../settings/domain/entities/refresh_interval.dart';
import 'auto_refresh_status.dart';

class AutoRefreshState {
  const AutoRefreshState({
    required this.enabled,
    required this.interval,
    required this.status,
    required this.lastAttemptAt,
    required this.lastSuccessAt,
    required this.nextEligibleAt,
    required this.cooldownUntil,
    required this.lastError,
    required this.isRefreshInProgress,
  });

  factory AutoRefreshState.initial() {
    return const AutoRefreshState(
      enabled: false,
      interval: RefreshInterval.off,
      status: AutoRefreshStatus.disabled,
      lastAttemptAt: null,
      lastSuccessAt: null,
      nextEligibleAt: null,
      cooldownUntil: null,
      lastError: null,
      isRefreshInProgress: false,
    );
  }

  final bool enabled;
  final RefreshInterval interval;
  final AutoRefreshStatus status;
  final DateTime? lastAttemptAt;
  final DateTime? lastSuccessAt;
  final DateTime? nextEligibleAt;
  final DateTime? cooldownUntil;
  final String? lastError;
  final bool isRefreshInProgress;

  AutoRefreshState copyWith({
    bool? enabled,
    RefreshInterval? interval,
    AutoRefreshStatus? status,
    DateTime? lastAttemptAt,
    DateTime? lastSuccessAt,
    DateTime? nextEligibleAt,
    bool clearNextEligibleAt = false,
    DateTime? cooldownUntil,
    bool clearCooldownUntil = false,
    String? lastError,
    bool clearLastError = false,
    bool? isRefreshInProgress,
  }) {
    return AutoRefreshState(
      enabled: enabled ?? this.enabled,
      interval: interval ?? this.interval,
      status: status ?? this.status,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      nextEligibleAt: clearNextEligibleAt
          ? null
          : nextEligibleAt ?? this.nextEligibleAt,
      cooldownUntil: clearCooldownUntil
          ? null
          : cooldownUntil ?? this.cooldownUntil,
      lastError: clearLastError ? null : lastError ?? this.lastError,
      isRefreshInProgress: isRefreshInProgress ?? this.isRefreshInProgress,
    );
  }
}
