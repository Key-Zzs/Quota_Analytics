import '../../../refresh/domain/entities/manual_refresh_page_state.dart';
import '../entities/auto_refresh_result.dart';
import '../repositories/auto_refresh_repository.dart';

class RunForegroundAutoRefresh {
  const RunForegroundAutoRefresh(this.repository);

  final AutoRefreshRepository repository;

  Future<AutoRefreshResult> call(ManualRefreshPageState pageState) {
    return repository.refreshCurrentPage(pageState);
  }
}
