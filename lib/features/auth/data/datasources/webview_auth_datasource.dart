import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../domain/entities/web_auth_config.dart';
import '../../domain/entities/web_auth_navigation_error.dart';
import '../../domain/entities/webview_clear_result.dart';

typedef WebViewBlockedCallback = void Function(String rawUrl, String reason);

class WebViewAuthDataSource {
  WebViewAuthDataSource({
    required WebAuthConfig config,
    required void Function(int progress) onProgress,
    required void Function(String rawUrl) onPageStarted,
    required void Function(String rawUrl) onPageFinished,
    required void Function(String rawUrl) onUrlChanged,
    required void Function(WebAuthNavigationError error) onWebResourceError,
    required WebViewBlockedCallback onNavigationBlocked,
  }) : cookieManager = WebViewCookieManager(),
       webViewController = WebViewController(
         onPermissionRequest: (request) {
           unawaited(request.deny());
           onNavigationBlocked(
             'about:blank',
             'Web content requested a device permission. Stage 4 denies WebView permission requests.',
           );
         },
       ) {
    unawaited(webViewController.setBackgroundColor(Colors.transparent));
    unawaited(webViewController.setJavaScriptMode(JavaScriptMode.unrestricted));
    unawaited(
      webViewController.setNavigationDelegate(
        NavigationDelegate(
          onProgress: onProgress,
          onPageStarted: onPageStarted,
          onPageFinished: onPageFinished,
          onUrlChange: (change) {
            final url = change.url;
            if (url != null) {
              onUrlChanged(url);
            }
          },
          onNavigationRequest: (request) {
            if (request.isMainFrame &&
                !config.isSupportedNavigationUrl(request.url)) {
              onNavigationBlocked(
                request.url,
                'Only HTTPS main-frame navigation is allowed in Stage 4.',
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) {
              return;
            }
            onWebResourceError(
              WebAuthNavigationError(
                description: error.description,
                errorCode: error.errorCode,
                errorType: error.errorType?.name,
              ),
            );
          },
        ),
      ),
    );
  }

  final WebViewController webViewController;
  final WebViewCookieManager cookieManager;

  Future<void> load(Uri uri) {
    return webViewController.loadRequest(uri);
  }

  Future<void> reload() {
    return webViewController.reload();
  }

  Future<void> goBack() {
    return webViewController.goBack();
  }

  Future<void> goForward() {
    return webViewController.goForward();
  }

  Future<bool> canGoBack() {
    return webViewController.canGoBack();
  }

  Future<bool> canGoForward() {
    return webViewController.canGoForward();
  }

  Future<String?> currentUrl() {
    return webViewController.currentUrl();
  }

  Future<String?> pageTitle() {
    return webViewController.getTitle();
  }

  Future<WebViewClearResult> clearWebViewData() async {
    final unsupportedOperations = <String>[];
    var cacheCleared = false;
    var localStorageCleared = false;
    var cookiesCleared = false;

    try {
      await webViewController.clearCache();
      cacheCleared = true;
    } catch (_) {
      unsupportedOperations.add('cache');
    }

    try {
      await webViewController.clearLocalStorage();
      localStorageCleared = true;
    } catch (_) {
      unsupportedOperations.add('localStorage');
    }

    try {
      await cookieManager.clearCookies();
      cookiesCleared = true;
    } catch (_) {
      unsupportedOperations.add('cookies');
    }

    return WebViewClearResult(
      cacheCleared: cacheCleared,
      localStorageCleared: localStorageCleared,
      cookiesCleared: cookiesCleared,
      unsupportedOperations: unsupportedOperations,
    );
  }
}
