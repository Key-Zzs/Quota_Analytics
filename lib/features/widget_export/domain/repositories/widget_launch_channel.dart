import 'dart:async';

import '../entities/widget_launch_action.dart';

typedef WidgetLaunchActionHandler = FutureOr<void> Function(
  WidgetLaunchAction action,
);

abstract class WidgetLaunchChannel {
  Future<WidgetLaunchAction?> consumeInitialLaunchAction();

  void setLaunchActionHandler(WidgetLaunchActionHandler? handler);
}

class NoopWidgetLaunchChannel implements WidgetLaunchChannel {
  const NoopWidgetLaunchChannel();

  @override
  Future<WidgetLaunchAction?> consumeInitialLaunchAction() async => null;

  @override
  void setLaunchActionHandler(WidgetLaunchActionHandler? handler) {}
}
