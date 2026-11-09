import 'dart:convert';

import 'package:cpe_reviewer/data/pack_repository.dart';
import 'package:cpe_reviewer/models/subject_pack.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

Map<String, dynamic> question(String id, String stem) => {
  'id': id,
  'termId': 'prelim',
  'handoutId': 'prelim-01',
  'topic': 'Topic',
  'difficulty': 'easy',
  'stem': stem,
  'options': ['Correct', 'Wrong A', 'Wrong B', 'Wrong C'],
  'answerIndex': 0,
  'explanation': 'Explanation for $id',
  'sourcePage': 1,
};

Map<String, dynamic> fullPack() => {
  'id': 'test-pack',
  'subject': 'Test Subject',
  'code': 'TST101',
  'org': 'Test Org',
  'version': '1.0.0',
  'description': 'Test',
  'authors': ['Tester'],
  'license': 'Test only',
  'terms': [
    {'id': 'prelim', 'name': 'Prelim', 'order': 1, 'defaultWeight': 20},
  ],
  'handouts': [
    {
      'id': 'prelim-01',
      'termId': 'prelim',
      'number': '01',
      'title': 'Test handout',
    },
  ],
  'questions': [question('q1', 'First question?')],
};

void main() {
  test('installs a full pack and merges question-only updates', () async {
    final database = await databaseFactoryMemory.openDatabase('test.db');
    final repository = PackRepository(database);

    await repository.importJsonString(jsonEncode(fullPack()));
    var packs = await repository.loadAll();
    expect(packs.length, 1);
    expect(packs.single.questions.length, 1);

    final merged = await repository.importJsonString(
      jsonEncode({
        'subjectId': 'test-pack',
        'version': '1.1.0',
        'questions': [
          question('q2', 'Second question?'),
          question('q1', 'Replacement first question?'),
        ],
      }),
    );

    expect(merged.version, '1.1.0');
    expect(merged.questions.length, 2);
    expect(
      merged.questions.firstWhere((item) => item.id == 'q1').stem,
      'Replacement first question?',
    );
  });

  test('rejects an invalid question', () async {
    final database = await databaseFactoryMemory.openDatabase('test2.db');
    final repository = PackRepository(database);
    final pack = fullPack();
    final broken = question('bad', 'Broken?')
      ..['options'] = ['Only one', 'Two', 'Three'];
    pack['questions'] = [broken];

    expect(
      () => repository.importJsonString(jsonEncode(pack)),
      throwsA(isA<PackValidationException>()),
    );
  });

  test('validates the bundled pack metadata', () {
    final pack = SubjectPack.fromJson(fullPack());
    expect(SubjectPack.validate(pack), isEmpty);
    expect(pack.defaultWeights, {'prelim': 20});
  });
}
