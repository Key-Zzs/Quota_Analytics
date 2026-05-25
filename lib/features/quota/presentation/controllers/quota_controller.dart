import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_error.dart';
import '../../domain/entities/quota_persistence_status.dart';
import '../../domain/entities/quota_snapshot.dart';
import '../../domain/repositories/quota_repository.dart';
import '../../domain/usecases/clear_quota_history.dart';
import '../../domain/usecases/get_latest_quota_snapshot.dart';
import '../../domain/usecases/get_quota_history.dart';
import '../../domain/usecases/get_quota_persistence_status.dart';
import '../../domain/usecases/refresh_quota_snapshot.dart';

enum QuotaPageStatus { loading, success, empty, error }

class QuotaController extends ChangeNotifier {
  QuotaController({required QuotaRepository repository})
    : _getLatestSnapshot = GetLatestQuotaSnapshot(repository),
      _refreshSnapshot = RefreshQuotaSnapshot(repository),
      _getQuotaHistory = GetQuotaHistory(repository),
      _clearQuotaHistory = ClearQuotaHistory(repository),
      _getPersistenceStatus = GetQuotaPersistenceStatus(repository);

  final GetLatestQuotaSnapshot _getLatestSnapshot;
  final RefreshQuotaSnapshot _refreshSnapshot;
  final GetQuotaHistory _getQuotaHistory;
  final ClearQuotaHistory _clearQuotaHistory;
  final GetQuotaPersistenceStatus _getPersistenceStatus;

  QuotaPageStatus _status = QuotaPageStatus.loading;
  QuotaSnapshot? _snapshot;
  List<QuotaSnapshot> _history = const [];
  QuotaPersistenceStatus _persistenceStatus = QuotaPersistenceStatus.mockOnly();
  String? _errorMessage;
  String _lastRefreshResult = 'Not refreshed yet';
  Duration? _lastRefreshDuration;

  QuotaPageStatus get status => _status;
  QuotaSnapshot? get snapshot => _snapshot;
  List<QuotaSnapshot> get history => _history;
  QuotaPersistenceStatus get persistenceStatus => _persistenceStatus;
  String? get errorMessage => _errorMessage;
  String get lastRefreshResult => _lastRefreshResult;
  Duration? get lastRefreshDuration => _lastRefreshDuration;
  bool get isLoading => _status == QuotaPageStatus.loading;

  Future<void> loadLatestSnapshot() async {
    _status = QuotaPageStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _getLatestSnapshot();
      _applySnapshot(snapshot);
      await _refreshPersistenceState();
      _lastRefreshResult = _persistenceStatus.loadedFromLocalCache
          ? 'Loaded last snapshot from local cache'
          : 'Initial mock snapshot loaded';
    } on Object catch (error) {
      _status = QuotaPageStatus.error;
      _errorMessage = AppError('Unable to load quota', cause: error).toString();
    }

    notifyListeners();
  }

  Future<void> refresh() async {
    _status = QuotaPageStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    try {
      final snapshot = await _refreshSnapshot();
      stopwatch.stop();
      _lastRefreshDuration = stopwatch.elapsed;
      _lastRefreshResult = 'Refresh succeeded';
      _applySnapshot(snapshot);
      await _refreshPersistenceState();
    } on Object catch (error) {
      stopwatch.stop();
      _lastRefreshDuration = stopwatch.elapsed;
      _lastRefreshResult = 'Refresh failed';
      _status = QuotaPageStatus.error;
      _errorMessage = AppError(
        'Unable to refresh quota',
        cause: error,
      ).toString();
    }

    notifyListeners();
  }

  void markExternalRefreshStarted(String message) {
    _status = QuotaPageStatus.loading;
    _errorMessage = null;
    _lastRefreshResult = message;
    _lastRefreshDuration = null;
    notifyListeners();
  }

  Future<void> completeExternalRefreshWithoutSnapshot(
    String message, {
    Duration? refreshDuration,
  }) async {
    _status = _snapshot == null
        ? QuotaPageStatus.empty
        : QuotaPageStatus.success;
    _errorMessage = null;
    _lastRefreshResult = message;
    _lastRefreshDuration = refreshDuration;
    await _refreshPersistenceState();
    notifyListeners();
  }

  Future<void> failExternalRefresh(
    String message, {
    required Object cause,
    Duration? refreshDuration,
  }) async {
    _status = QuotaPageStatus.error;
    _lastRefreshDuration = refreshDuration;
    _lastRefreshResult = message;
    _errorMessage = AppError(message, cause: cause).toString();
    await _refreshPersistenceState();
    notifyListeners();
  }

  Future<void> reloadHistory() async {
    await _refreshPersistenceState();
    notifyListeners();
  }

  Future<void> applySavedSnapshot(
    QuotaSnapshot snapshot, {
    String resultMessage = 'Parsed snapshot saved locally',
    Duration? refreshDuration,
  }) async {
    _applySnapshot(snapshot);
    _lastRefreshResult = resultMessage;
    _lastRefreshDuration = refreshDuration;
    await _refreshPersistenceState();
    notifyListeners();
  }

  Future<void> clearLocalData() async {
    _status = QuotaPageStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _clearQuotaHistory();
      final snapshot = await _getLatestSnapshot();
      _applySnapshot(snapshot);
      _lastRefreshResult = 'Local data cleared; mock default loaded';
      _lastRefreshDuration = null;
      await _refreshPersistenceState();
    } on Object catch (error) {
      _status = QuotaPageStatus.error;
      _errorMessage = AppError(
        'Unable to clear local quota data',
        cause: error,
      ).toString();
    }

    notifyListeners();
  }

  void _applySnapshot(QuotaSnapshot snapshot) {
    _snapshot = snapshot;
    _status = QuotaPageStatus.success;
    _errorMessage = null;
  }

  Future<void> _refreshPersistenceState() async {
    _history = await _getQuotaHistory();
    _persistenceStatus = await _getPersistenceStatus();
  }
}
