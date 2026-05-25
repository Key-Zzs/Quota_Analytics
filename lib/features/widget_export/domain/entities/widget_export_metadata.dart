import 'widget_export_status.dart';

class WidgetExportMetadata {
  const WidgetExportMetadata({
    required this.status,
    required this.lastExportedAt,
    required this.lastExportError,
  });

  factory WidgetExportMetadata.initial() {
    return const WidgetExportMetadata(
      status: WidgetExportStatus.neverExported,
      lastExportedAt: null,
      lastExportError: null,
    );
  }

  final WidgetExportStatus status;
  final DateTime? lastExportedAt;
  final String? lastExportError;

  WidgetExportMetadata copyWith({
    WidgetExportStatus? status,
    DateTime? lastExportedAt,
    String? lastExportError,
    bool clearLastExportError = false,
  }) {
    return WidgetExportMetadata(
      status: status ?? this.status,
      lastExportedAt: lastExportedAt ?? this.lastExportedAt,
      lastExportError: clearLastExportError
          ? null
          : lastExportError ?? this.lastExportError,
    );
  }
}
