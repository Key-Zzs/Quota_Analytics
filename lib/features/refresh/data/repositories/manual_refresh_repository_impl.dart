import '../../domain/entities/manual_refresh_result.dart';
import '../../domain/repositories/manual_refresh_repository.dart';
import '../datasources/local_manual_refresh_datasource.dart';
import '../models/manual_refresh_result_model.dart';

class ManualRefreshRepositoryImpl implements ManualRefreshRepository {
  const ManualRefreshRepositoryImpl({required this.localDataSource});

  final LocalManualRefreshDataSource localDataSource;

  @override
  Future<ManualRefreshResult?> getLastResult() {
    return localDataSource.loadLast();
  }

  @override
  Future<ManualRefreshResult> saveLastResult(ManualRefreshResult result) {
    return localDataSource.saveLast(
      ManualRefreshResultModel.fromEntity(result),
    );
  }

  @override
  Future<void> clearLastResult() {
    return localDataSource.clearLast();
  }
}
