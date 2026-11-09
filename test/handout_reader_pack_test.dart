import 'dart:convert';
import 'dart:io';

import 'package:cpe_reviewer/data/handout_reader_repository.dart';
import 'package:cpe_reviewer/models/handout_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const expectedHandouts = {'it2205': 8, 'it2102': 5, 'it1919': 6};
  final packs = <String, HandoutReaderPack>{};

  setUpAll(() async {
    for (final entry in expectedHandouts.entries) {
      final file = File('assets/handouts/${entry.key}_reader.json');
      expect(
        await file.exists(),
        isTrue,
        reason: 'Run tools/build_subjects.py',
      );
      final decoded =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final pack = HandoutReaderPack.fromJson(decoded);
      packs[entry.key] = pack;
    }
  });

  test('reader packs validate and cover all handouts', () {
    for (final entry in expectedHandouts.entries) {
      final pack = packs[entry.key]!;
      expect(HandoutReaderRepository.validatePack(pack), isEmpty);
      expect(pack.subjectId, entry.key);
      expect(pack.handouts.length, entry.value);
      expect(pack.allTerms, isNotEmpty);
      for (final handout in pack.handouts) {
        expect(handout.sections, isNotEmpty);
        expect(handout.terms, isNotEmpty);
        expect(handout.tables, isNotEmpty);
        for (final table in handout.tables) {
          expect(table.headers.length, greaterThanOrEqualTo(2));
          for (final row in table.rows) {
            expect(row.length, table.headers.length);
          }
        }
      }
    }
  });

  test('full-text chunks exist for every reader handout', () async {
    for (final entry in expectedHandouts.entries) {
      final file = File('assets/handouts/${entry.key}.json');
      final decoded =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final chunks = decoded['chunks'] as List<dynamic>;
      final handoutIds = {
        for (final chunk in chunks) (chunk as Map)['handoutId'] as String,
      };
      for (final handout in packs[entry.key]!.handouts) {
        expect(handoutIds, contains(handout.id));
      }
    }
  });

  test('search finds facts in all three subjects', () {
    final lawHits = HandoutReaderRepository.instance.search(
      packs['it2205']!,
      'RA 10175',
    );
    expect(lawHits, isNotEmpty);

    final embeddedHits = HandoutReaderRepository.instance.search(
      packs['it2102']!,
      'Pulse Width Modulation',
    );
    expect(embeddedHits, isNotEmpty);

    final robotHits = HandoutReaderRepository.instance.search(
      packs['it1919']!,
      'Fulcrum',
    );
    expect(robotHits, isNotEmpty);
  });
}
