import '../entities/extracted_page_text.dart';
import '../repositories/page_text_extraction_repository.dart';

class ExtractCurrentPageText {
  const ExtractCurrentPageText(this.repository);

  final PageTextExtractionRepository repository;

  Future<ExtractedPageText> call() {
    return repository.extractCurrentPageText();
  }
}
