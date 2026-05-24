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
        final topMaxHeight = MediaQuery.sizeOf(context).height < 700
            ? 184.0
            : 232.0;
        return SafeArea(
          child: Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: topMaxHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Column(
                    children: [
                      const WebViewSafetyNotice(),
                      const SizedBox(height: 8),
                      WebViewControls(controller: _controller),
                      const SizedBox(height: 8),
                      WebViewStatusBar(controller: _controller),
                    ],
                  ),
                ),
              ),
              Expanded(
                key: const ValueKey('webview-expanded-region'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: _WebViewFrame(
                    child:
                        widget.webViewBuilder?.call(context, _controller) ??
                        _webView ??
                        const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
              _BottomActionPanel(
                webAuthController: _controller,
                pageTextExtractionController:
                    widget.pageTextExtractionController,
                quotaParserController: widget.quotaParserController,
                manualRefreshController: widget.manualRefreshController,
                onSnapshotSaved: widget.onParsedSnapshotSaved,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomActionPanel extends StatelessWidget {
  const _BottomActionPanel({
    required this.webAuthController,
    required this.pageTextExtractionController,
    required this.quotaParserController,
    required this.manualRefreshController,
    required this.onSnapshotSaved,
  });

  final WebViewAuthController webAuthController;
  final PageTextExtractionController? pageTextExtractionController;
  final QuotaParserController? quotaParserController;
  final ManualRefreshController? manualRefreshController;
  final ValueChanged<QuotaSnapshot>? onSnapshotSaved;

  @override
  Widget build(BuildContext context) {
    if (manualRefreshController == null &&
        pageTextExtractionController == null) {
      return const SizedBox.shrink();
    }

    final maxHeight = MediaQuery.sizeOf(context).height < 700 ? 176.0 : 220.0;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Material(
          elevation: 3,
          color: Theme.of(context).colorScheme.surface,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            shrinkWrap: true,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (manualRefreshController != null)
                      ManualRefreshButton(
                        isBusy: manualRefreshController!.isBusy,
                        onPressed: () => unawaited(_runManualRefresh()),
                      ),
                    if (manualRefreshController != null &&
                        pageTextExtractionController != null)
                      const SizedBox(width: 8),
                    if (pageTextExtractionController != null)
                      OutlinedButton.icon(
                        onPressed: pageTextExtractionController!.isExtracting
                            ? null
                            : () => unawaited(
                                pageTextExtractionController!
                                    .extractCurrentPageText(),
                              ),
                        icon: const Icon(Icons.text_snippet_outlined),
                        label: Text(
                          pageTextExtractionController!.isExtracting
                              ? 'Extracting Page Text...'
                              : 'Extract Page Text',
                        ),
                      ),
                  ],
                ),
              ),
              if (manualRefreshController != null)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: const Text('Manual refresh details'),
                  children: [
                    ManualRefreshStatusCard(
                      controller: manualRefreshController!,
                    ),
                    const SizedBox(height: 8),
                    ManualRefreshResultCard(
                      controller: manualRefreshController!,
                      onSnapshotSaved: onSnapshotSaved,
                    ),
                  ],
                ),
              if (pageTextExtractionController != null)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: const Text('Extraction details'),
                  children: [
                    ExtractionStatusCard(
                      controller: pageTextExtractionController!,
                      quotaParserController: quotaParserController,
                      onParsedSnapshotSaved: onSnapshotSaved,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runManualRefresh() async {
    final controller = manualRefreshController;
    if (controller == null) {
      return;
    }
    final saved = await controller.refreshFromCurrentPage(
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
  const _WebViewFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.public, color: colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'WebView container',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant),
                color: colorScheme.surface,
              ),
              child: SizedBox.expand(child: child),
            ),
          ),
        ),
      ],
    );
  }
}
