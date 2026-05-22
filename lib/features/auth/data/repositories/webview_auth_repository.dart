import '../../domain/entities/webview_clear_result.dart';
import '../../domain/repositories/web_auth_repository.dart';
import '../datasources/webview_auth_datasource.dart';

class WebViewAuthRepositoryImpl implements WebAuthRepository {
  const WebViewAuthRepositoryImpl({required this.dataSource});

  final WebViewAuthDataSource dataSource;

  @override
  Future<void> load(Uri uri) {
    return dataSource.load(uri);
  }

  @override
  Future<void> reload() {
    return dataSource.reload();
  }

  @override
  Future<void> goBack() {
    return dataSource.goBack();
  }

  @override
  Future<void> goForward() {
    return dataSource.goForward();
  }

  @override
  Future<bool> canGoBack() {
    return dataSource.canGoBack();
  }

  @override
  Future<bool> canGoForward() {
    return dataSource.canGoForward();
  }

  @override
  Future<String?> currentUrl() {
    return dataSource.currentUrl();
  }

  @override
  Future<String?> pageTitle() {
    return dataSource.pageTitle();
  }

  @override
  Future<WebViewClearResult> clearWebViewData() {
    return dataSource.clearWebViewData();
  }
}
