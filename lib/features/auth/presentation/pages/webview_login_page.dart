import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/utils/date_time_format.dart';
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
import '../../../settings/presentation/controllers/settings_controller.dart';
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
    this.settingsController,
    this.onParsedSnapshotSaved,
    this.webViewBuilder,
  });

  final WebViewAuthController? controller;
  final PageTextExtractionController? pageTextExtractionController;
  final QuotaParserController? quotaParserController;
  final ManualRefreshController? manualRefreshController;
  final SettingsController? settingsController;
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
        widget.settingsController,
      ]),
      builder: (context, _) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                key: const ValueKey('webview-expanded-region'),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _WebViewFrame(
                    child:
                        widget.webViewBuilder?.call(context, _controller) ??
                        _webView ??
                        const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 8,
                child: FilledButton.icon(
                  key: const ValueKey('webview-container-control'),
                  onPressed: () => _showWebViewContainerPanel(context),
                  icon: const Icon(Icons.web_asset),
                  label: const Text('WebView container'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showWebViewContainerPanel(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: _WebViewContainerPanel(
            webAuthController: _controller,
            pageTextExtractionController: widget.pageTextExtractionController,
            quotaParserController: widget.quotaParserController,
            manualRefreshController: widget.manualRefreshController,
            settingsController: widget.settingsController,
            onSnapshotSaved: widget.onParsedSnapshotSaved,
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
        );
      },
    );
  }
}

class _WebViewContainerPanel extends StatelessWidget {
  const _WebViewContainerPanel({
    required this.webAuthController,
    required this.pageTextExtractionController,
    required this.quotaParserController,
    required this.manualRefreshController,
    required this.settingsController,
    required this.onSnapshotSaved,
    required this.onClose,
  });

  final WebViewAuthController webAuthController;
  final PageTextExtractionController? pageTextExtractionController;
  final QuotaParserController? quotaParserController;
  final ManualRefreshController? manualRefreshController;
  final SettingsController? settingsController;
  final ValueChanged<QuotaSnapshot>? onSnapshotSaved;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        webAuthController,
        pageTextExtractionController,
        quotaParserController,
        manualRefreshController,
        settingsController,
      ]),
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Row(
              children: [
                Icon(
                  Icons.web_asset,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'WebView container',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Close WebView container controls',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            WebViewControls(controller: webAuthController),
            const SizedBox(height: 8),
            const WebViewSafetyNotice(),
            const SizedBox(height: 8),
            WebViewStatusBar(controller: webAuthController),
            const SizedBox(height: 8),
            _BottomActionPanel(
              webAuthController: webAuthController,
              pageTextExtractionController: pageTextExtractionController,
              quotaParserController: quotaParserController,
              manualRefreshController: manualRefreshController,
              settingsController: settingsController,
              onSnapshotSaved: onSnapshotSaved,
            ),
          ],
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
    required this.settingsController,
    required this.onSnapshotSaved,
  });

  final WebViewAuthController webAuthController;
  final PageTextExtractionController? pageTextExtractionController;
  final QuotaParserController? quotaParserController;
  final ManualRefreshController? manualRefreshController;
  final SettingsController? settingsController;
  final ValueChanged<QuotaSnapshot>? onSnapshotSaved;

  @override
  Widget build(BuildContext context) {
    if (manualRefreshController == null &&
        pageTextExtractionController == null) {
      return const SizedBox.shrink();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (settingsController != null && manualRefreshController != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reload page before manual refresh'),
                subtitle: Text(
                  settingsController!.reloadBeforeManualRefreshEnabled
                      ? 'Manual Refresh will reload the page first.'
                      : 'Manual Refresh reads the current rendered page.',
                ),
                value: settingsController!.reloadBeforeManualRefreshEnabled,
                onChanged: settingsController!.isSaving
                    ? null
                    : (value) =>
                          unawaited(_setReloadBeforeManualRefresh(value)),
              ),
            if (settingsController != null && manualRefreshController != null)
              _ReloadStatusSummary(webAuthController: webAuthController),
            if (settingsController != null && manualRefreshController != null)
              const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
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
            ),
            if (manualRefreshController != null)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text('Manual refresh details'),
                children: [
                  ManualRefreshStatusCard(controller: manualRefreshController!),
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

  Future<void> _setReloadBeforeManualRefresh(bool value) async {
    final controller = settingsController;
    if (controller == null) {
      return;
    }
    controller.setReloadBeforeManualRefreshEnabled(value);
    await controller.save();
  }
}

class _ReloadStatusSummary extends StatelessWidget {
  const _ReloadStatusSummary({required this.webAuthController});

  final WebViewAuthController webAuthController;

  @override
  Widget build(BuildContext context) {
    final error = webAuthController.lastReloadError;
    return Align(
      alignment: Alignment.centerLeft,
      child: DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.bodySmall,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last reload status: ${webAuthController.lastReloadStatus}'),
            Text(
              'Last reload duration: ${formatDuration(webAuthController.lastReloadDuration)}',
            ),
            const Text('Reload timeout: 15 seconds'),
            if (error != null)
              Text(
                'Last reload error: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}

class _WebViewFrame extends StatelessWidget {
  const _WebViewFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          color: colorScheme.surface,
        ),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}
