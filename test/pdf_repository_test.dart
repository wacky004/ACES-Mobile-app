import 'package:cpe_reviewer/data/pdf_repository.dart';
import 'package:cpe_reviewer/models/imported_pdf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  test('stores PDFs and draft sets, and deleting a PDF removes its drafts',
      () async {
    final database = await databaseFactoryMemory.openDatabase('pdfs.db');
    final repository = PdfRepository(database);

    final pdf = ImportedPdf(
      id: 'pdf-1',
      filename: 'handout.pdf',
      pages: 2,
      createdAt: DateTime(2026, 1, 1),
      ocrUsed: false,
      chunks: const [
        PdfChunk(id: 'p1-c1', page: 1, text: 'First page text'),
        PdfChunk(id: 'p2-c1', page: 2, text: 'Second page text'),
      ],
    );
    await repository.savePdf(pdf);

    final draft = DraftSet(
      id: 'draft-1',
      pdfId: 'pdf-1',
      filename: 'handout.pdf',
      createdAt: DateTime(2026, 1, 2),
      questions: const [
        DraftQuestion(
          id: 'q1',
          sourcePage: 1,
          topic: 'Topic',
          difficulty: 'easy',
          stem: 'Question?',
          options: ['A', 'B', 'C', 'D'],
          answerIndex: 0,
          explanation: 'Because A.',
        ),
      ],
    );
    await repository.saveDraft(draft);

    expect((await repository.listPdfs()).single.chunks.length, 2);
    expect((await repository.listDrafts()).single.questions.length, 1);

    await repository.deletePdf('pdf-1');
    expect(await repository.listPdfs(), isEmpty);
    expect(await repository.listDrafts(), isEmpty);
  });
}
