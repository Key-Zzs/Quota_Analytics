import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_error.dart';
import '../../domain/entities/quota_snapshot.dart';
import '../../domain/repositories/quota_repository.dart';
import '../../domain/usecases/get_latest_quota_snapshot.dart';
import '../../domain/usecases/refresh_quota_snapshot.dart';

enum QuotaPageStatus { loading, success, empty, error }

class QuotaController extends ChangeNotifier {
  QuotaController({required QuotaRepository repository})
    : _getLatestSnapshot = GetLatestQuotaSnapshot(repository),
      _refreshSnapshot = RefreshQuotaSnapshot(repository);

  final GetLatestQuotaSnapshot _getLatestSnapshot;
  final RefreshQuotaSnapshot _refreshSnapshot;

  QuotaPageStatus _status = QuotaPageStatus.loading;
  QuotaSnapshot? _snapshot;
  String? _errorMessage;
  String _lastRefreshResult = 'Not refreshed yet';
  Duration? _lastRefreshDuration;

  QuotaPageStatus get status => _status;
  QuotaSnapshot? get snapshot => _snapshot;
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
      _lastRefreshResult = 'Initial mock snapshot loaded';
    } on Object catch (error) {
      _status = QuotaPageStatus.error;
      _errorMessage = AppError(
        'Unable to load mock quota',
        cause: error,
      ).toString();
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
    } on Object catch (error) {
      stopwatch.stop();
      _lastRefreshDuration = stopwatch.elapsed;
      _lastRefreshResult = 'Refresh failed';
      _status = QuotaPageStatus.error;
      _errorMessage = AppError(
        'Unable to refresh mock quota',
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
}
