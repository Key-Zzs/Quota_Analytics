import '../../../../core/security/sensitive_data_policy.dart';
import 'reload_before_refresh_status.dart';

class ReloadBeforeRefreshResult {
  const ReloadBeforeRefreshResult({
    required this.status,
    required this.startedAt,
    required this.finishedAt,
    required this.sanitizedUrl,
    required this.warnings,
    required this.errors,
  });

  factory ReloadBeforeRefreshResult.idle(DateTime now) {
    return ReloadBeforeRefreshResult(
      status: ReloadBeforeRefreshStatus.idle,
      startedAt: now,
      finishedAt: null,
      sanitizedUrl: 'none',
      warnings: const [],
      errors: const [],
    );
  }

  final ReloadBeforeRefreshStatus status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String? sanitizedUrl;
  final List<String> warnings;
  final List<String> errors;

  Duration? get duration {
    final finished = finishedAt;
    return finished?.difference(startedAt);
  }

  bool get allowsExtraction => status.allowsExtraction;

  ReloadBeforeRefreshResult copyWith({
    ReloadBeforeRefreshStatus? status,
    DateTime? startedAt,
    DateTime? finishedAt,
    bool clearFinishedAt = false,
    String? sanitizedUrl,
    List<String>? warnings,
    List<String>? errors,
  }) {
    return ReloadBeforeRefreshResult(
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: clearFinishedAt ? null : finishedAt ?? this.finishedAt,
      sanitizedUrl: sanitizedUrl ?? this.sanitizedUrl,
      warnings: _sanitizeList(warnings ?? this.warnings),
      errors: _sanitizeList(errors ?? this.errors),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'status': status.name,
      'startedAt': startedAt.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
      'sanitizedUrl': sanitizedUrl,
      'warnings': warnings,
      'errors': errors,
    };
  }

  static ReloadBeforeRefreshResult fromJson(Map<String, Object?> json) {
    return ReloadBeforeRefreshResult(
      status: reloadBeforeRefreshStatusFromStorageKey(
        _readString(json['status']),
      ),
      startedAt:
          DateTime.tryParse(_readString(json['startedAt']) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      finishedAt: DateTime.tryParse(_readString(json['finishedAt']) ?? ''),
      sanitizedUrl: _readString(json['sanitizedUrl']) ?? 'none',
      warnings: _readStringList(json['warnings']),
      errors: _readStringList(json['errors']),
    );
  }

  static List<String> _sanitizeList(List<String> values) {
    return values
        .map(SensitiveDataPolicy.sanitizeLogText)
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
  }

  static String? _readString(Object? value) {
    return value is String ? value : null;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<String>().toList(growable: false);
  }
}
