import '../entities/extracted_page_text.dart';

abstract class CurrentPageTextReader {
  Future<String?> currentUrl();

  Future<String?> pageTitle();

  Future<String> readBodyInnerText();
}

abstract class PageTextExtractionRepository {
  void attachPageTextReader(CurrentPageTextReader reader);

  Future<ExtractedPageText?> getLastExtractedPageText();

  Future<ExtractedPageText> extractCurrentPageText();

  Future<void> clearExtractedPageText();
}
