import '../repositories/background_refresh_repository.dart';

class CancelBackgroundRefresh {
  const CancelBackgroundRefresh(this.repository);

  final BackgroundRefreshRepository repository;

  Future<void> call() {
    return repository.cancel();
  }
}
