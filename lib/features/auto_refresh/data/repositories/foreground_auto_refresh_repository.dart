import '../../../refresh/domain/entities/manual_refresh_page_state.dart';
import '../../../refresh/presentation/controllers/manual_refresh_controller.dart';
import '../../domain/entities/auto_refresh_result.dart';
import '../../domain/repositories/auto_refresh_repository.dart';

class ForegroundAutoRefreshRepository implements AutoRefreshRepository {
  const ForegroundAutoRefreshRepository({
    required this.manualRefreshController,
  });

  final ManualRefreshController manualRefreshController;

  @override
  bool get isRefreshInProgress => manualRefreshController.isBusy;

  @override
  Future<AutoRefreshResult> refreshCurrentPage(
    ManualRefreshPageState pageState,
  ) async {
    final savedSnapshot = await manualRefreshController.refreshFromCurrentPage(
      pageState,
    );
    return AutoRefreshResult(
      manualRefreshResult: manualRefreshController.lastResult,
      savedSnapshot: savedSnapshot,
    );
  }
}
