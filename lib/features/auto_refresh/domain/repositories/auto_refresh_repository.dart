import '../../../refresh/data/services/page_load_waiter.dart';
import '../../../refresh/domain/entities/manual_refresh_page_state.dart';
import '../../../refresh/domain/entities/reload_before_refresh_result.dart';
import '../entities/auto_refresh_result.dart';

abstract class AutoRefreshRepository {
  bool get isRefreshInProgress;

  Future<AutoRefreshResult> refreshCurrentPage(
    ManualRefreshPageState pageState, {
    bool reloadBeforeRefresh = false,
    ReloadCancellationSignal? cancellationSignal,
    ReloadBeforeRefreshResult? reloadBeforeRefreshResult,
  });
}
