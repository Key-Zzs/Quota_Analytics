import '../repositories/page_text_extraction_repository.dart';

class ClearExtractedPageText {
  const ClearExtractedPageText(this.repository);

  final PageTextExtractionRepository repository;

  Future<void> call() {
    return repository.clearExtractedPageText();
  }
}
