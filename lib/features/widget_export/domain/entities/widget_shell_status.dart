class WidgetShellStatus {
  const WidgetShellStatus({
    required this.available,
    required this.installedWidgetCount,
    required this.hasInstalledWidgets,
    required this.safeError,
  });

  factory WidgetShellStatus.unknown({String? safeError}) {
    return WidgetShellStatus(
      available: null,
      installedWidgetCount: null,
      hasInstalledWidgets: null,
      safeError: safeError,
    );
  }

  final bool? available;
  final int? installedWidgetCount;
  final bool? hasInstalledWidgets;
  final String? safeError;

  String get availableLabel {
    return switch (available) {
      true => 'true',
      false => 'false',
      null => 'unknown',
    };
  }

  String get installedLabel {
    final hasWidgets = hasInstalledWidgets;
    final count = installedWidgetCount;
    if (hasWidgets == null || count == null) {
      return 'unknown';
    }
    return '$hasWidgets ($count)';
  }
}
