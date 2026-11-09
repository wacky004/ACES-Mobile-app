import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../models/imported_pdf.dart';

class PdfImportException implements Exception {
  PdfImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PdfImportService {
  static bool _pdfrxReady = false;

  Future<ImportedPdf> extract(
    Uint8List bytes,
    String filename, {
    required void Function(int progress, String status) onProgress,
    bool Function()? isCancelled,
  }) async {
    if (bytes.isEmpty) {
      throw PdfImportException('The selected PDF is empty.');
    }
    if (bytes.length > 120 * 1024 * 1024) {
      throw PdfImportException(
        'This PDF is over 120 MB. Choose a smaller file or split it first.',
      );
    }
    if (!_pdfrxReady) {
      await pdfrxFlutterInitialize();
      _pdfrxReady = true;
    }

    PdfDocument? document;
    TextRecognizer? recognizer;
    final chunks = <PdfChunk>[];
    var ocrUsed = false;
    try {
      document = await PdfDocument.openData(bytes, sourceName: filename);
      final pages = document.pages;
      if (pages.isEmpty) {
        throw PdfImportException('The PDF has no pages.');
      }

      for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
        if (isCancelled?.call() ?? false) {
          throw PdfImportException('Import cancelled.');
        }
        final page = pages[pageIndex];
        final pageNumber = pageIndex + 1;
        onProgress(
          ((pageIndex / pages.length) * 100).round(),
          'Reading page $pageNumber of ${pages.length}',
        );

        var text = '';
        try {
          final raw = await page.loadText();
          text = raw?.fullText.trim() ?? '';
        } catch (_) {
          text = '';
        }

        if (text.length < 30) {
          onProgress(
            ((pageIndex / pages.length) * 100).round(),
            'OCR page $pageNumber of ${pages.length}',
          );
          try {
            recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
            final pageWidth = page.width <= 0 ? 1.0 : page.width;
            final pageHeight = page.height <= 0 ? 1.0 : page.height;
            final fullWidth = 1500.0;
            final fullHeight = fullWidth * pageHeight / pageWidth;
            final image = await page.render(
              fullWidth: fullWidth,
              fullHeight: fullHeight,
            );
            if (image != null) {
              final input = InputImage.fromBitmap(
                bitmap: image.pixels,
                width: image.width,
                height: image.height,
              );
              final recognized = await recognizer.processImage(input);
              text = recognized.text.trim();
              image.dispose();
              if (text.isNotEmpty) ocrUsed = true;
            }
          } catch (_) {
            text = '';
          }
        }

        final pageChunks = _splitPageText(text);
        for (var index = 0; index < pageChunks.length; index++) {
          chunks.add(
            PdfChunk(
              id: 'p$pageNumber-c${index + 1}',
              page: pageNumber,
              text: pageChunks[index],
            ),
          );
        }
      }

      onProgress(100, 'Done');
      return ImportedPdf(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        filename: filename,
        pages: pages.length,
        createdAt: DateTime.now(),
        chunks: chunks,
        ocrUsed: ocrUsed,
      );
    } on PdfImportException {
      rethrow;
    } catch (error) {
      throw PdfImportException('Could not read this PDF: $error');
    } finally {
      try {
        await document?.dispose();
      } catch (_) {}
      try {
        recognizer?.close();
      } catch (_) {}
    }
  }

  List<String> _splitPageText(String text) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return const [];
    if (cleaned.length <= 800) return [cleaned];
    final sentences = cleaned.split(RegExp(r'(?<=[.!?])\s+'));
    final chunks = <String>[];
    final buffer = StringBuffer();
    for (final sentence in sentences) {
      if (buffer.length + sentence.length > 750 && buffer.isNotEmpty) {
        chunks.add(buffer.toString().trim());
        buffer.clear();
      }
      buffer.write(sentence);
      buffer.write(' ');
    }
    if (buffer.toString().trim().isNotEmpty) {
      chunks.add(buffer.toString().trim());
    }
    return chunks;
  }
}
