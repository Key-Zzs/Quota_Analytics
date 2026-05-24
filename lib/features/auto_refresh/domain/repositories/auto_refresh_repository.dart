import '../../../refresh/domain/entities/manual_refresh_page_state.dart';
import '../entities/auto_refresh_result.dart';

abstract class AutoRefreshRepository {
  bool get isRefreshInProgress;

  Future<AutoRefreshResult> refreshCurrentPage(
    ManualRefreshPageState pageState,
  );
}
