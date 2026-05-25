enum WidgetExportStatus { neverExported, success, failed, cleared }

extension WidgetExportStatusLabel on WidgetExportStatus {
  String get storageKey => name;

  String get label {
    return switch (this) {
      WidgetExportStatus.neverExported => 'never_exported',
      WidgetExportStatus.success => 'success',
      WidgetExportStatus.failed => 'failed',
      WidgetExportStatus.cleared => 'cleared',
    };
  }
}

WidgetExportStatus widgetExportStatusFromStorageKey(String? value) {
  return WidgetExportStatus.values.firstWhere(
    (status) => status.storageKey == value,
    orElse: () => WidgetExportStatus.neverExported,
  );
}
