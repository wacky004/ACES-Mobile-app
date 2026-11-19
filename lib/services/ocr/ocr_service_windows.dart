import 'package:flutter/services.dart';

import 'ocr_service.dart';

class WindowsOcrService implements OcrService {
  static const MethodChannel _channel = MethodChannel('aces/ocr');

  @override
  Future<String> recognize({
    required Uint8List pixels,
    required int width,
    required int height,
  }) async {
    final result = await _channel.invokeMethod<String>('recognizeText', {
      'bytes': pixels,
      'width': width,
      'height': height,
    });
    return result?.trim() ?? '';
  }

  @override
  Future<void> dispose() async {}
}
