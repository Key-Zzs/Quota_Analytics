import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

import '../../domain/repositories/page_text_extraction_repository.dart';

class PageTextExtractionJavaScript {
  const PageTextExtractionJavaScript._();

  // Stage 4 is limited to visible page text. Do not add cookie, storage,
  // HTML, request, response, or network-hook reads here.
  static const documentBodyInnerTextOnly =
      "(() => document.body ? document.body.innerText : '')();";
}

class WebViewTextExtractionDataSource implements CurrentPageTextReader {
  const WebViewTextExtractionDataSource({required this.webViewController});

  final WebViewController webViewController;

  @override
  Future<String?> currentUrl() {
    return webViewController.currentUrl();
  }

  @override
  Future<String?> pageTitle() {
    return webViewController.getTitle();
  }

  @override
  Future<String> readBodyInnerText() async {
    final result = await webViewController.runJavaScriptReturningResult(
      PageTextExtractionJavaScript.documentBodyInnerTextOnly,
    );
    return _normalizeJavaScriptStringResult(result);
  }

  String _normalizeJavaScriptStringResult(Object? result) {
    if (result == null) {
      return '';
    }
    if (result is! String) {
      return result.toString();
    }

    final trimmed = result.trim();
    if (trimmed == 'null') {
      return '';
    }

    if (trimmed.length >= 2 &&
        ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
            (trimmed.startsWith("'") && trimmed.endsWith("'")))) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is String) {
          return decoded;
        }
      } on FormatException {
        return result;
      }
    }

    return result;
  }
}
