import '../../../refresh/data/services/page_load_waiter.dart';
import '../../../refresh/domain/entities/manual_refresh_page_state.dart';
import '../../../refresh/domain/entities/reload_before_refresh_result.dart';
import '../entities/auto_refresh_result.dart';
import '../repositories/auto_refresh_repository.dart';

class RunForegroundAutoRefresh {
  const RunForegroundAutoRefresh(this.repository);

  final AutoRefreshRepository repository;

  Future<AutoRefreshResult> call(
    ManualRefreshPageState pageState, {
    ReloadCancellationSignal? cancellationSignal,
    ReloadBeforeRefreshResult? reloadBeforeRefreshResult,
  }) {
    return repository.refreshCurrentPage(
      pageState,
      cancellationSignal: cancellationSignal,
      reloadBeforeRefreshResult: reloadBeforeRefreshResult,
    );
  }
}
