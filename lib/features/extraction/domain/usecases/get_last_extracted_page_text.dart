import '../entities/extracted_page_text.dart';
import '../repositories/page_text_extraction_repository.dart';

class GetLastExtractedPageText {
  const GetLastExtractedPageText(this.repository);

  final PageTextExtractionRepository repository;

  Future<ExtractedPageText?> call() {
    return repository.getLastExtractedPageText();
  }
}
