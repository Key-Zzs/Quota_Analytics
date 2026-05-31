import 'package:flutter_test/flutter_test.dart';
import 'package:quota_analytics/features/widget_export/domain/entities/widget_launch_action.dart';

void main() {
  test('source widget target quota routes to Quota page', () {
    final action = WidgetLaunchAction.fromPlatformMap(const {
      'source': 'widget',
      'target': 'quota',
    });

    final decision = const WidgetLaunchRouter().resolve(action);

    expect(action.source, WidgetLaunchSource.widget);
    expect(action.target, WidgetLaunchTarget.quota);
    expect(decision.destination, WidgetLaunchDestination.quota);
    expect(decision.showRefreshPrompt, isFalse);
  });

  test('source widget target refreshUsagePage routes to refresh entry', () {
    final action = WidgetLaunchAction.fromPlatformMap(const {
      'source': 'widget',
      'target': 'refreshUsagePage',
      'action': 'openRefreshFlow',
    });

    final decision = const WidgetLaunchRouter().resolve(action);

    expect(decision.destination, WidgetLaunchDestination.refreshUsagePage);
    expect(decision.showRefreshPrompt, isTrue);
  });

  test('unknown target defaults to Quota page', () {
    final action = WidgetLaunchAction.fromPlatformMap(const {
      'source': 'widget',
      'target': 'https://example.invalid/?token=secret',
    });

    final decision = const WidgetLaunchRouter().resolve(action);

    expect(action.target, WidgetLaunchTarget.quota);
    expect(decision.destination, WidgetLaunchDestination.quota);
  });

  test('no sensitive extras are required', () {
    final action = WidgetLaunchAction.fromPlatformMap(const {
      'source': 'widget',
      'target': 'refreshUsagePage',
      'action': 'openRefreshFlow',
    });

    expect(action.source, 'widget');
    expect(action.target, 'refreshUsagePage');
    expect(action.action, 'openRefreshFlow');
  });
}
