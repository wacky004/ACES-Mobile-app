import 'package:cpe_reviewer/data/reader_progress_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'reader progress persists read state, terms, font, and position',
    () async {
      SharedPreferences.setMockInitialValues({});
      final controller = ReaderProgressController();
      await controller.load();
      expect(controller.fontSize, 16);
      expect(controller.isRead('prelim-01'), isFalse);

      await controller.markRead('prelim-01', true);
      await controller.setTermKnown('p01-cpe', true);
      await controller.setFontSize(20);
      await controller.saveLast('it2205', 'prelim-01', 'nature');

      final restored = ReaderProgressController();
      await restored.load();
      expect(restored.isRead('prelim-01'), isTrue);
      expect(restored.isTermKnown('p01-cpe'), isTrue);
      expect(restored.fontSize, 20);
      expect(restored.lastHandoutFor('it2205'), 'prelim-01');
      expect(restored.lastSectionFor('it2205'), 'nature');
    },
  );
}
