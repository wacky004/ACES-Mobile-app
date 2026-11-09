import 'package:cpe_reviewer/models/handout_reader.dart';
import 'package:cpe_reviewer/services/reader_text_parts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('splits long pages into parts without losing text', () {
    final sentences = List.generate(
      20,
      (index) => 'Sentence number $index contains enough text for reading.',
    ).join(' ');
    final parts = buildReaderTextParts([
      ReaderFullTextPage(handoutId: 'h1', page: 1, text: sentences),
      ReaderFullTextPage(
        handoutId: 'h1',
        page: 2,
        text: 'A short page that stays in one part.',
      ),
    ], maxChars: 160);
    expect(parts.length, greaterThan(2));
    expect(parts.first.page, 1);
    expect(parts.last.page, 2);
    expect(parts.last.count, 1);
    expect(parts.last.text, contains('A short page'));
    for (final part in parts) {
      expect(part.text, isNotEmpty);
      expect(part.text.length, lessThanOrEqualTo(180));
    }
    final joined = parts
        .where((part) => part.page == 1)
        .map((part) => part.text)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    expect(joined, sentences.replaceAll(RegExp(r'\s+'), ' '));
  });
}
