import 'dart:convert';

import '../../../../core/storage/json_storage.dart';
import '../../../../core/storage/local_storage_keys.dart';
import '../models/extracted_page_text_model.dart';

class LocalExtractedTextDataSource {
  const LocalExtractedTextDataSource({required this.storage});

  final JsonStorage storage;

  Future<ExtractedPageTextModel?> loadLast() async {
    final raw = await storage.readString(LocalStorageKeys.extractedPageText);
    if (raw == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('extracted text root is not a JSON object');
      }
      return ExtractedPageTextModel.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on Object {
      await clear();
      return null;
    }
  }

  Future<void> saveLast(ExtractedPageTextModel model) {
    return storage.writeString(
      LocalStorageKeys.extractedPageText,
      jsonEncode(model.toJson()),
    );
  }

  Future<void> clear() {
    return storage.remove(LocalStorageKeys.extractedPageText);
  }
}
