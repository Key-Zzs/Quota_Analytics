import '../entities/webview_clear_result.dart';

abstract class WebAuthRepository {
  Future<void> load(Uri uri);

  Future<void> reload();

  Future<void> goBack();

  Future<void> goForward();

  Future<bool> canGoBack();

  Future<bool> canGoForward();

  Future<String?> currentUrl();

  Future<String?> pageTitle();

  Future<WebViewClearResult> clearWebViewData();
}
