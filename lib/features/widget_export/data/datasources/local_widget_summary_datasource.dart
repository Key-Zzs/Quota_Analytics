import 'dart:convert';

import '../../../../core/security/sensitive_data_policy.dart';
import '../../../../core/serialization/date_time_converter.dart';
import '../../../../core/storage/json_storage.dart';
import '../../../../core/storage/local_storage_keys.dart';
import '../../domain/entities/widget_export_metadata.dart';
import '../../domain/entities/widget_export_status.dart';
import '../../domain/entities/widget_snapshot_summary.dart';
import '../models/widget_snapshot_summary_model.dart';

class LocalWidgetSummaryDataSource {
  const LocalWidgetSummaryDataSource({required this.storage});

  final JsonStorage storage;

  Future<void> saveSummary(WidgetSnapshotSummary summary) async {
    final model = WidgetSnapshotSummaryModel.fromEntity(summary);
    await storage.writeString(
      LocalStorageKeys.widgetLatestSummaryJson,
      jsonEncode(model.toJson()),
    );
    await saveMetadata(
      WidgetExportMetadata(
        status: WidgetExportStatus.success,
        lastExportedAt: summary.exportedAt,
        lastExportError: null,
      ),
    );
  }

  Future<WidgetSnapshotSummaryModel?> loadSummary() async {
    final raw = await storage.readString(
      LocalStorageKeys.widgetLatestSummaryJson,
    );
    if (raw == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('widget summary root is not an object');
      }
      return WidgetSnapshotSummaryModel.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on Object catch (error) {
      await storage.remove(LocalStorageKeys.widgetLatestSummaryJson);
      await saveMetadata(
        WidgetExportMetadata(
          status: WidgetExportStatus.failed,
          lastExportedAt: null,
          lastExportError:
              'Invalid widget summary JSON: ${SensitiveDataPolicy.sanitizeLogText(error.toString())}',
        ),
      );
      return null;
    }
  }

  Future<void> clearSummary({DateTime? clearedAt}) async {
    await storage.remove(LocalStorageKeys.widgetLatestSummaryJson);
    await saveMetadata(
      WidgetExportMetadata(
        status: WidgetExportStatus.cleared,
        lastExportedAt: clearedAt,
        lastExportError: null,
      ),
    );
  }

  Future<WidgetExportMetadata> loadMetadata() async {
    final status = widgetExportStatusFromStorageKey(
      await storage.readString(LocalStorageKeys.widgetExportStatus),
    );
    final exportedAt = dateTimeFromIso8601(
      await storage.readString(LocalStorageKeys.widgetLastExportedAt),
    );
    final error = await storage.readString(
      LocalStorageKeys.widgetLastExportError,
    );

    return WidgetExportMetadata(
      status: status,
      lastExportedAt: exportedAt,
      lastExportError: error,
    );
  }

  Future<void> saveMetadata(WidgetExportMetadata metadata) async {
    await storage.writeString(
      LocalStorageKeys.widgetExportStatus,
      metadata.status.storageKey,
    );
    final exportedAt = dateTimeToIso8601(metadata.lastExportedAt);
    if (exportedAt == null) {
      await storage.remove(LocalStorageKeys.widgetLastExportedAt);
    } else {
      await storage.writeString(
        LocalStorageKeys.widgetLastExportedAt,
        exportedAt,
      );
    }

    final error = metadata.lastExportError;
    if (error == null || error.trim().isEmpty) {
      await storage.remove(LocalStorageKeys.widgetLastExportError);
    } else {
      await storage.writeString(
        LocalStorageKeys.widgetLastExportError,
        SensitiveDataPolicy.sanitizeLogText(error),
      );
    }
  }
}
