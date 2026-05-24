import 'dart:async';

import 'package:flutter/foundation.dart';

enum PageLoadWaitStatus { completed, timeout, cancelled, failed }

class PageLoadWaitResult {
  const PageLoadWaitResult({required this.status, this.errorMessage});

  final PageLoadWaitStatus status;
  final String? errorMessage;
}

abstract class PageLoadStateReader implements Listenable {
  bool get isPageLoading;
  DateTime? get lastPageFinishedAt;
  DateTime? get lastWebResourceErrorAt;
  String? get lastWebResourceError;
}

abstract class ReloadCancellationSignal implements Listenable {
  bool get isCancelled;
}

class ReloadCancellationToken extends ChangeNotifier
    implements ReloadCancellationSignal {
  bool _isCancelled = false;

  @override
  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) {
      return;
    }
    _isCancelled = true;
    notifyListeners();
  }
}

class PageLoadWaiter {
  const PageLoadWaiter();

  Future<PageLoadWaitResult> waitForPageFinished({
    required PageLoadStateReader pageState,
    required DateTime reloadStartedAt,
    required Duration timeout,
    required Duration settleDelay,
    ReloadCancellationSignal? cancellationSignal,
    VoidCallback? onSettleStarted,
  }) {
    final completer = Completer<PageLoadWaitResult>();
    Timer? timeoutTimer;
    Timer? settleTimer;
    var settling = false;
    late void Function() evaluate;

    void complete(PageLoadWaitResult result) {
      if (completer.isCompleted) {
        return;
      }
      timeoutTimer?.cancel();
      settleTimer?.cancel();
      pageState.removeListener(evaluate);
      cancellationSignal?.removeListener(evaluate);
      completer.complete(result);
    }

    void completeIfSettled() {
      if (cancellationSignal?.isCancelled ?? false) {
        complete(
          const PageLoadWaitResult(status: PageLoadWaitStatus.cancelled),
        );
        return;
      }
      if (pageState.isPageLoading) {
        settling = false;
        evaluate();
        return;
      }
      final errorAt = pageState.lastWebResourceErrorAt;
      if (errorAt != null && !errorAt.isBefore(reloadStartedAt)) {
        complete(
          PageLoadWaitResult(
            status: PageLoadWaitStatus.failed,
            errorMessage: pageState.lastWebResourceError,
          ),
        );
        return;
      }
      complete(const PageLoadWaitResult(status: PageLoadWaitStatus.completed));
    }

    void startSettleDelay() {
      if (settling) {
        return;
      }
      settling = true;
      onSettleStarted?.call();
      settleTimer = Timer(settleDelay, completeIfSettled);
    }

    evaluate = () {
      if (completer.isCompleted) {
        return;
      }
      if (cancellationSignal?.isCancelled ?? false) {
        complete(
          const PageLoadWaitResult(status: PageLoadWaitStatus.cancelled),
        );
        return;
      }
      final errorAt = pageState.lastWebResourceErrorAt;
      if (errorAt != null && !errorAt.isBefore(reloadStartedAt)) {
        complete(
          PageLoadWaitResult(
            status: PageLoadWaitStatus.failed,
            errorMessage: pageState.lastWebResourceError,
          ),
        );
        return;
      }
      final finishedAt = pageState.lastPageFinishedAt;
      if (finishedAt == null || finishedAt.isBefore(reloadStartedAt)) {
        return;
      }
      if (pageState.isPageLoading) {
        return;
      }
      startSettleDelay();
    };

    timeoutTimer = Timer(timeout, () {
      complete(const PageLoadWaitResult(status: PageLoadWaitStatus.timeout));
    });
    pageState.addListener(evaluate);
    cancellationSignal?.addListener(evaluate);
    scheduleMicrotask(evaluate);
    return completer.future;
  }
}
