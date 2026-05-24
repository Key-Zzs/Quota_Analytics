import 'dart:io';

class AndroidPlatformCapabilities {
  const AndroidPlatformCapabilities({
    bool? isAndroid,
    this.hasBackgroundSafeDataSource = false,
  }) : _isAndroidOverride = isAndroid;

  final bool? _isAndroidOverride;
  final bool hasBackgroundSafeDataSource;

  bool get isAndroid => _isAndroidOverride ?? Platform.isAndroid;

  bool get supportsWorkManager => isAndroid;
}
