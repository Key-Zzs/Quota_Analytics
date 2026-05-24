import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../extraction/data/datasources/webview_text_extraction_datasource.dart';
import '../../../extraction/presentation/controllers/page_text_extraction_controller.dart';
import '../../../extraction/presentation/widgets/extraction_status_card.dart';
import '../../../parser/presentation/controllers/quota_parser_controller.dart';
import '../../../quota/domain/entities/quota_snapshot.dart';
import '../../../refresh/domain/entities/manual_refresh_page_state.dart';
import '../../../refresh/presentation/controllers/manual_refresh_controller.dart';
import '../../../refresh/presentation/widgets/manual_refresh_button.dart';
import '../../../refresh/presentation/widgets/manual_refresh_result_card.dart';
import '../../../refresh/presentation/widgets/manual_refresh_status_card.dart';
import '../../data/datasources/webview_auth_datasource.dart';
import '../../data/repositories/webview_auth_repository.dart';
import '../controllers/webview_auth_controller.dart';
import '../widgets/webview_controls.dart';
import '../widgets/webview_safety_notice.dart';
import '../widgets/webview_status_bar.dart';

typedef AuthWebViewBuilder =
    Widget Function(BuildContext context, WebViewAuthController controller);

class WebViewLoginPage extends StatefulWidget {
  const WebViewLoginPage({
    super.key,
    this.controller,
    this.pageTextExtractionController,
    this.quotaParserController,
    this.manualRefreshController,
    this.onParsedSnapshotSaved,
    this.webViewBuilder,
  });

  final WebViewAuthController? controller;
  final PageTextExtractionController? pageTextExtractionController;
  final QuotaParserController? quotaParserController;
  final ManualRefreshController? manualRefreshController;
  final ValueChanged<QuotaSnapshot>? onParsedSnapshotSaved;
  final AuthWebViewBuilder? webViewBuilder;

  @override
  State<WebViewLoginPage> createState() => _WebViewLoginPageState();
}

class _WebViewLoginPageState extends State<WebViewLoginPage> {
  late final WebViewAuthController _controller;
  late final bool _ownsController;
  Widget? _webView;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? WebViewAuthController();

    if (widget.webViewBuilder == null) {
      final dataSource = WebViewAuthDataSource(
        config: _controller.config,
        onProgress: _controller.onProgress,
        onPageStarted: _controller.onPageStarted,
        onPageFinished: (rawUrl) =>
            unawaited(_controller.onPageFinished(rawUrl)),
        onUrlChanged: _controller.onUrlChanged,
        onWebResourceError: _controller.onWebResourceError,
        onNavigationBlocked: _controller.onNavigationBlocked,
      );
      _controller.attachRepository(
        WebViewAuthRepositoryImpl(dataSource: dataSource),
      );
      widget.pageTextExtractionController?.attachPageTextReader(
        WebViewTextExtractionDataSource(
          webViewController: dataSource.webViewController,
        ),
      );
      _webView = WebViewWidget(controller: dataSource.webViewController);
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _controller,
        widget.pageTextExtractionController,
        widget.quotaParserController,
        widget.manualRefreshController,
      ]),
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final webViewHeight = constraints.maxHeight < 700 ? 360.0 : 460.0;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Official Web Login',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Official website is loaded inside WebView. This app stays outside the credential boundary.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                const WebViewSafetyNotice(),
                const SizedBox(height: 12),
                WebViewControls(controller: _controller),
                const SizedBox(height: 12),
                WebViewStatusBar(controller: _controller),
                if (widget.manualRefreshController != null) ...[
                  const SizedBox(height: 12),
                  _ManualRefreshSection(
                    webAuthController: _controller,
                    manualRefreshController: widget.manualRefreshController!,
                    onSnapshotSaved: widget.onParsedSnapshotSaved,
                  ),
                ],
                if (widget.pageTextExtractionController != null) ...[
                  const SizedBox(height: 12),
                  ExtractionStatusCard(
                    controller: widget.pageTextExtractionController!,
                    quotaParserController: widget.quotaParserController,
                    onParsedSnapshotSaved: widget.onParsedSnapshotSaved,
                  ),
                ],
                const SizedBox(height: 12),
                _WebViewFrame(
                  height: webViewHeight,
                  child:
                      widget.webViewBuilder?.call(context, _controller) ??
                      _webView ??
                      const Center(child: CircularProgressIndicator()),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ManualRefreshSection extends StatelessWidget {
  const _ManualRefreshSection({
    required this.webAuthController,
    required this.manualRefreshController,
    required this.onSnapshotSaved,
  });

  final WebViewAuthController webAuthController;
  final ManualRefreshController manualRefreshController;
  final ValueChanged<QuotaSnapshot>? onSnapshotSaved;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ManualRefreshButton(
          isBusy: manualRefreshController.isBusy,
          onPressed: () => unawaited(_runManualRefresh()),
        ),
        const SizedBox(height: 12),
        ManualRefreshStatusCard(controller: manualRefreshController),
        const SizedBox(height: 12),
        ManualRefreshResultCard(
          controller: manualRefreshController,
          onSnapshotSaved: onSnapshotSaved,
        ),
      ],
    );
  }

  Future<void> _runManualRefresh() async {
    final saved = await manualRefreshController.refreshFromCurrentPage(
      ManualRefreshPageState(
        currentUrl: webAuthController.currentUrl,
        pageTitle: webAuthController.pageTitle,
        isLoading: webAuthController.isLoading,
        isReady: webAuthController.isReady,
      ),
    );
    if (saved != null) {
      onSnapshotSaved?.call(saved);
    }
  }
}

class _WebViewFrame extends StatelessWidget {
  const _WebViewFrame({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WebView container',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              color: colorScheme.surface,
            ),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
