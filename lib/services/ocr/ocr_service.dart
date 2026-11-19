import 'dart:io';
import 'dart:typed_data';

import 'ocr_service_android.dart';
import 'ocr_service_windows.dart';

abstract class OcrService {
  static OcrService create() {
    if (Platform.isAndroid) return MlKitOcrService();
    if (Platform.isWindows) return WindowsOcrService();
    throw UnsupportedError('OCR is not available on this platform.');
  }

  Future<String> recognize({
    required Uint8List pixels,
    required int width,
    required int height,
  });

  Future<void> dispose();
}
