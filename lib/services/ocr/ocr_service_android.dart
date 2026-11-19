import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_service.dart';

class MlKitOcrService implements OcrService {
  TextRecognizer? _recognizer;

  @override
  Future<String> recognize({
    required Uint8List pixels,
    required int width,
    required int height,
  }) async {
    final recognizer = _recognizer ??= TextRecognizer(
      script: TextRecognitionScript.latin,
    );
    final input = InputImage.fromBitmap(
      bitmap: pixels,
      width: width,
      height: height,
    );
    final recognized = await recognizer.processImage(input);
    return recognized.text.trim();
  }

  @override
  Future<void> dispose() async {
    _recognizer?.close();
    _recognizer = null;
  }
}
