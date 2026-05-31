import 'package:flutter/services.dart';

import '../../../../core/platform/runtime_platform.dart';
import '../../../../core/security/sensitive_data_policy.dart';
import '../../domain/entities/widget_launch_action.dart';
import '../../domain/repositories/widget_launch_channel.dart';
import 'android_widget_update_channel.dart';

typedef AndroidRuntimeProvider = bool Function();

class AndroidWidgetLaunchChannel implements WidgetLaunchChannel {
  AndroidWidgetLaunchChannel({
    MethodChannel channel = const MethodChannel(
      AndroidWidgetUpdateChannel.channelName,
    ),
    AndroidRuntimeProvider? isAndroidProvider,
  }) : _channel = channel,
       _isAndroidProvider = isAndroidProvider ?? _defaultIsRuntimeAndroid;

  static const _methodConsumeLaunchAction = 'consumeWidgetLaunchAction';
  static const _methodWidgetLaunchAction = 'widgetLaunchAction';

  final MethodChannel _channel;
  final AndroidRuntimeProvider _isAndroidProvider;
  WidgetLaunchActionHandler? _handler;

  bool get _isAndroid => _isAndroidProvider();

  @override
  Future<WidgetLaunchAction?> consumeInitialLaunchAction() async {
    if (!_isAndroid) {
      return null;
    }
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        _methodConsumeLaunchAction,
      );
      if (raw == null) {
        return null;
      }
      return WidgetLaunchAction.fromPlatformMap(raw);
    } on Object catch (_) {
      return null;
    }
  }

  @override
  void setLaunchActionHandler(WidgetLaunchActionHandler? handler) {
    _handler = handler;
    if (!_isAndroid || handler == null) {
      _channel.setMethodCallHandler(null);
      return;
    }

    _channel.setMethodCallHandler((call) async {
      if (call.method != _methodWidgetLaunchAction) {
        return null;
      }
      try {
        await _handler?.call(
          WidgetLaunchAction.fromPlatformMap(call.arguments),
        );
      } on Object catch (error) {
        SensitiveDataPolicy.sanitizeLogText(error.toString());
      }
      return null;
    });
  }
}

bool _defaultIsRuntimeAndroid() => isRuntimeAndroid;
