import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

import '../../models/deepseek_models.dart';

class PdfAttachmentCancelled implements Exception {
  const PdfAttachmentCancelled();
}

class PdfAttachmentException implements Exception {
  const PdfAttachmentException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PdfAttachmentService {
  static bool _pdfrxReady = false;

  Future<DeepSeekAttachment> prepare(
    Uint8List bytes,
    String filename, {
    void Function(int page, int total, String status)? onProgress,
    bool Function()? isCancelled,
    int maxPages = 30,
    int maxImages = 12,
    int maxTextChars = 60000,
  }) async {
    if (bytes.isEmpty) {
      throw const PdfAttachmentException('The selected PDF is empty.');
    }
    if (!_pdfrxReady) {
      await pdfrxFlutterInitialize();
      _pdfrxReady = true;
    }

    PdfDocument? document;
    try {
      document = await PdfDocument.openData(bytes, sourceName: filename);
      final pages = document.pages;
      if (pages.isEmpty) {
        throw const PdfAttachmentException('The PDF has no pages.');
      }
      final textBuffer = StringBuffer();
      final pageImages = <DeepSeekPageImage>[];
      var imageBytes = 0;
      var omittedImages = 0;
      final limit = pages.length < maxPages ? pages.length : maxPages;

      for (var index = 0; index < limit; index++) {
        if (isCancelled?.call() ?? false) {
          throw const PdfAttachmentCancelled();
        }
        final page = pages[index];
        final pageNumber = index + 1;
        onProgress?.call(
          pageNumber,
          limit,
          'Reading page $pageNumber of $limit',
        );

        var text = '';
        try {
          final raw = await page.loadText();
          text = raw?.fullText.trim() ?? '';
        } catch (_) {
          text = '';
        }

        if (text.length >= 80) {
          final remaining = maxTextChars - textBuffer.length;
          if (remaining > 200) {
            final clipped = text.length > remaining
                ? '${text.substring(0, remaining)}…'
                : text;
            textBuffer
              ..writeln('[Page $pageNumber]')
              ..writeln(clipped);
          }
        } else {
          if (pageImages.length >= maxImages ||
              imageBytes >= 24 * 1024 * 1024) {
            omittedImages++;
            continue;
          }
          try {
            final pageWidth = page.width <= 0 ? 1.0 : page.width;
            final pageHeight = page.height <= 0 ? 1.0 : page.height;
            const targetWidth = 1600.0;
            const maxHeight = 8000.0;
            var scale = targetWidth / pageWidth;
            if (pageHeight * scale > maxHeight) {
              scale = maxHeight / pageHeight;
            }
            final renderWidth = pageWidth * scale;
            final renderHeight = pageHeight * scale;
            final rendered = await page.render(
              fullWidth: renderWidth,
              fullHeight: renderHeight,
            );
            if (rendered != null) {
              final raster = img.Image.fromBytes(
                width: rendered.width,
                height: rendered.height,
                bytes: rendered.pixels.buffer,
                bytesOffset: rendered.pixels.offsetInBytes,
                numChannels: 4,
                order: img.ChannelOrder.bgra,
              );
              final jpeg = img.encodeJpg(raster, quality: 82);
              rendered.dispose();
              if (imageBytes + jpeg.length <= 24 * 1024 * 1024) {
                pageImages.add(
                  DeepSeekPageImage(page: pageNumber, bytes: jpeg),
                );
                imageBytes += jpeg.length;
              } else {
                omittedImages++;
              }
            }
          } catch (_) {
            omittedImages++;
          }
        }
      }

      final notes = <String>[];
      if (pages.length > limit) {
        notes.add('Showing the first $limit of ${pages.length} pages.');
      }
      if (omittedImages > 0) {
        notes.add(
          '$omittedImages page(s) could not be included as images. '
          'Split the PDF or reduce the page count.',
        );
      }
      if (textBuffer.length >= maxTextChars) {
        notes.add('The text was truncated to keep the request within limits.');
      }
      return DeepSeekAttachment(
        kind: DeepSeekAttachmentKind.pdf,
        filename: filename,
        text: textBuffer.isEmpty ? null : textBuffer.toString().trim(),
        pageImages: pageImages,
        pageCount: pages.length,
        note: notes.join(' '),
      );
    } on PdfAttachmentCancelled {
      rethrow;
    } on PdfAttachmentException {
      rethrow;
    } catch (error) {
      throw PdfAttachmentException('Could not read this PDF: $error');
    } finally {
      try {
        await document?.dispose();
      } catch (_) {}
    }
  }
}
