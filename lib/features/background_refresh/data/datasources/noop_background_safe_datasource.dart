import '../../domain/repositories/background_safe_quota_data_source.dart';

class NoopBackgroundSafeDataSource implements BackgroundSafeQuotaDataSource {
  const NoopBackgroundSafeDataSource();

  @override
  bool get isAvailable => false;

  @override
  String? get identifier => null;
}
