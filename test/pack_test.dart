import 'dart:convert';
import 'dart:io';

import 'package:cpe_reviewer/models/subject_pack.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final id in ['it2205', 'it2102', 'it1919']) {
    test('bundled $id pack is valid and complete', () async {
      final file = File('assets/packs/$id.json');
      expect(
        await file.exists(),
        isTrue,
        reason: 'Run tools/build_subjects.py',
      );

      final decoded =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final pack = SubjectPack.fromJson(decoded);

      expect(SubjectPack.validate(pack), isEmpty);
      expect(pack.questions.length, 160);
      expect(pack.terms.map((term) => term.id).toSet(), {
        'prelim',
        'midterm',
        'prefinals',
        'finals',
      });

      for (final term in pack.terms) {
        final items = pack.questions
            .where((question) => question.termId == term.id)
            .toList(growable: false);
        expect(items.length, 40, reason: '${term.name} should have 40 items');
        expect(
          items
              .where((question) => question.type == QuestionType.multipleChoice)
              .length,
          30,
        );
        expect(
          items
              .where(
                (question) => question.type == QuestionType.modifiedTrueFalse,
              )
              .length,
          10,
        );
      }

      final questionIds = <String>{};
      for (final question in pack.questions) {
        expect(questionIds.add(question.id), isTrue);
        if (question.isModifiedTrueFalse) {
          expect(question.options, ['True', 'False']);
          expect(question.answerIndex, inInclusiveRange(0, 1));
          expect(question.underlined, isNotEmpty);
          expect(question.stem, contains(question.underlined));
          if (question.answerIndex == 1) {
            expect(question.correction, isNotEmpty);
          }
        } else {
          expect(question.options.length, 4);
          expect(question.answerIndex, inInclusiveRange(0, 3));
          expect(question.options.toSet().length, 4);
        }
        expect(question.stem, isNotEmpty);
        expect(question.explanation, isNotEmpty);
        expect(pack.termById(question.termId), isNotNull);
        expect(pack.handoutById(question.handoutId), isNotNull);
        expect(question.sourcePage, greaterThanOrEqualTo(1));
      }
    });
  }
}
