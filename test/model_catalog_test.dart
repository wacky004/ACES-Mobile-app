import 'package:cpe_reviewer/services/ai/ai_model_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog has six unique pinned models and a recommended default', () {
    expect(aiModelCatalog.length, 6);
    expect(aiModelCatalog.where((model) => model.recommended).length, 1);
    expect(defaultAiModel.id, 'qwen25_3b');
    final ids = <String>{};
    final filenames = <String>{};
    for (final model in aiModelCatalog) {
      expect(ids.add(model.id), isTrue);
      expect(filenames.add(model.filename), isTrue);
      expect(model.sizeBytes, greaterThan(100 * 1024 * 1024));
      expect(model.sha256.length, 64);
      expect(model.url, startsWith('https://'));
      expect(model.ramGuide, isNotEmpty);
      expect(model.license, isNotEmpty);
    }
  });

  test('lookup by id returns the right model', () {
    expect(aiModelById('gemma3_4b')?.filename, 'gemma-3-4b-it-Q4_K_M.gguf');
    expect(aiModelById('unknown'), isNull);
  });
}
