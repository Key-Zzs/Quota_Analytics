class WidgetLaunchSource {
  const WidgetLaunchSource._();

  static const widget = 'widget';
  static const unknown = 'unknown';
}

class WidgetLaunchTarget {
  const WidgetLaunchTarget._();

  static const quota = 'quota';
  static const refreshUsagePage = 'refreshUsagePage';
}

class WidgetLaunchIntentAction {
  const WidgetLaunchIntentAction._();

  static const openRefreshFlow = 'openRefreshFlow';
  static const openQuota = 'openQuota';
  static const unknown = 'unknown';
}

enum WidgetLaunchDestination { quota, refreshUsagePage }

class WidgetLaunchAction {
  const WidgetLaunchAction({
    required this.source,
    required this.target,
    required this.action,
  });

  factory WidgetLaunchAction.fromPlatformMap(Object? raw) {
    if (raw is! Map) {
      return const WidgetLaunchAction(
        source: WidgetLaunchSource.unknown,
        target: WidgetLaunchTarget.quota,
        action: WidgetLaunchIntentAction.unknown,
      );
    }

    final source = _readSafeEnum(
      raw['source'],
      allowedValues: const {WidgetLaunchSource.widget},
      fallback: WidgetLaunchSource.unknown,
    );
    final target = _readSafeEnum(
      raw['target'] ?? raw['open_route'],
      allowedValues: const {
        WidgetLaunchTarget.quota,
        WidgetLaunchTarget.refreshUsagePage,
      },
      fallback: WidgetLaunchTarget.quota,
    );
    final action = _readSafeEnum(
      raw['action'],
      allowedValues: const {
        WidgetLaunchIntentAction.openQuota,
        WidgetLaunchIntentAction.openRefreshFlow,
      },
      fallback: WidgetLaunchIntentAction.unknown,
    );

    return WidgetLaunchAction(source: source, target: target, action: action);
  }

  final String source;
  final String target;
  final String action;

  bool get isFromWidget => source == WidgetLaunchSource.widget;
}

class WidgetLaunchRouteDecision {
  const WidgetLaunchRouteDecision({
    required this.destination,
    required this.showRefreshPrompt,
  });

  final WidgetLaunchDestination destination;
  final bool showRefreshPrompt;
}

class WidgetLaunchRouter {
  const WidgetLaunchRouter();

  WidgetLaunchRouteDecision resolve(WidgetLaunchAction action) {
    if (action.target == WidgetLaunchTarget.refreshUsagePage ||
        action.action == WidgetLaunchIntentAction.openRefreshFlow) {
      return const WidgetLaunchRouteDecision(
        destination: WidgetLaunchDestination.refreshUsagePage,
        showRefreshPrompt: true,
      );
    }

    return const WidgetLaunchRouteDecision(
      destination: WidgetLaunchDestination.quota,
      showRefreshPrompt: false,
    );
  }
}

String _readSafeEnum(
  Object? value, {
  required Set<String> allowedValues,
  required String fallback,
}) {
  if (value is! String) {
    return fallback;
  }
  return allowedValues.contains(value) ? value : fallback;
}
