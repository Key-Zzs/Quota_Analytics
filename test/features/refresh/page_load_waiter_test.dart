import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/refresh/data/services/page_load_waiter.dart';

void main() {
  test('completes on pageFinished after settle delay', () async {
    final pageState = _FakePageLoadState();
    final waiter = const PageLoadWaiter();
    final startedAt = DateTime.now();
    var settleStarted = false;

    final future = waiter.waitForPageFinished(
      pageState: pageState,
      reloadStartedAt: startedAt,
      timeout: const Duration(milliseconds: 80),
      settleDelay: const Duration(milliseconds: 10),
      onSettleStarted: () {
        settleStarted = true;
      },
    );

    pageState.finish(startedAt.add(const Duration(milliseconds: 1)));

    final result = await future;
    expect(result.status, PageLoadWaitStatus.completed);
    expect(settleStarted, isTrue);
  });

  test('times out when pageFinished never arrives', () async {
    final result = await const PageLoadWaiter().waitForPageFinished(
      pageState: _FakePageLoadState(),
      reloadStartedAt: DateTime.now(),
      timeout: const Duration(milliseconds: 5),
      settleDelay: Duration.zero,
    );

    expect(result.status, PageLoadWaitStatus.timeout);
  });

  test('cancellation works while waiting', () async {
    final token = ReloadCancellationToken();
    final future = const PageLoadWaiter().waitForPageFinished(
      pageState: _FakePageLoadState(),
      reloadStartedAt: DateTime.now(),
      timeout: const Duration(milliseconds: 80),
      settleDelay: Duration.zero,
      cancellationSignal: token,
    );

    token.cancel();

    final result = await future;
    expect(result.status, PageLoadWaitStatus.cancelled);
  });
}

class _FakePageLoadState extends ChangeNotifier implements PageLoadStateReader {
  @override
  bool isPageLoading = true;

  @override
  DateTime? lastPageFinishedAt;

  @override
  DateTime? lastWebResourceErrorAt;

  @override
  String? lastWebResourceError;

  void finish(DateTime finishedAt) {
    isPageLoading = false;
    lastPageFinishedAt = finishedAt;
    notifyListeners();
  }
}
