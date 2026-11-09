import 'package:cpe_reviewer/data/pack_repository.dart';
import 'package:cpe_reviewer/models/subject_pack.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled subject packs seed and load together', () async {
    final database = await databaseFactoryMemory.openDatabase('bundled.db');
    final repository = PackRepository(database);
    await repository.seedBundledPacks();
    final packs = await repository.loadAll();
    expect(packs.map((pack) => pack.id).toSet(), {
      'it2205',
      'it2102',
      'it1919',
    });
    for (final pack in packs) {
      expect(SubjectPack.validate(pack), isEmpty);
      expect(pack.questions.length, 160);
      expect(
        pack.questions
            .where(
              (question) => question.type == QuestionType.modifiedTrueFalse,
            )
            .length,
        40,
      );
    }
    await database.close();
  });
}
