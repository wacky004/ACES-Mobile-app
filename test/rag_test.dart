import 'package:cpe_reviewer/services/ai/prompt_builder.dart';
import 'package:cpe_reviewer/services/ai/rag_index.dart';
import 'package:flutter_test/flutter_test.dart';

RagChunk chunk({
  required String id,
  required String handoutId,
  required String number,
  required String title,
  required int page,
  required String text,
  String termId = 'prelim',
}) => RagChunk(
  id: id,
  termId: termId,
  handoutId: handoutId,
  handoutNumber: number,
  handoutTitle: title,
  page: page,
  text: text,
);

void main() {
  final chunks = [
    chunk(
      id: 'a',
      handoutId: 'prelim-02',
      number: '02',
      title: 'Computer Engineering & IT Laws',
      page: 1,
      text:
          'The Cybercrime Prevention Act of 2012 is Republic Act No. 10175. '
          'It addresses crimes committed against and through computer systems.',
    ),
    chunk(
      id: 'b',
      handoutId: 'prelim-01',
      number: '01',
      title: 'Introduction to CPE Laws and Professional Practice',
      page: 2,
      text:
          'Integrity keeps professional people true to their word and stops '
          'them from compromising their values even when the road is harder.',
    ),
    chunk(
      id: 'c',
      handoutId: 'finals-08',
      number: '08',
      title: 'Application of IT Laws in the Computer Engineering Field',
      page: 1,
      text:
          'Everactive developed industrial sensors that can run nonstop for '
          'over 20 years with minimal maintenance.',
      termId: 'finals',
    ),
  ];

  test('BM25 retrieves the law and the sensor facts', () {
    final index = RagIndex.fromChunks(chunks);
    final law = index.search('Which law is RA 10175?');
    expect(law.first.id, 'a');

    final sensors = index.search('Everactive sensors 20 years');
    expect(sensors.first.id, 'c');
  });

  test('term filtering excludes other terms', () {
    final index = RagIndex.fromChunks(chunks);
    final results = index.search('Everactive sensors', termIds: {'prelim'});
    expect(results.any((item) => item.termId == 'finals'), isFalse);
  });

  test('prompt includes citations and the correct answer', () {
    final prompt = PromptBuilder.questionPrompt(
      question: 'Which law is the Cybercrime Prevention Act of 2012?',
      options: const ['RA 10175', 'RA 4200', 'RA 8792', 'RA 8484'],
      answerIndex: 0,
      explanation: 'It is Republic Act No. 10175.',
      chunks: [chunks.first],
      topic: 'Philippine IT laws',
    );
    expect(prompt, contains('HANDOUT EXCERPTS'));
    expect(prompt, contains('Handout 02'));
    expect(prompt, contains('Correct answer: A. RA 10175'));
    expect(prompt, contains('Cite the handout excerpt'));
  });

  test('draft prompt asks for strict JSON and source pages', () {
    final prompt = PromptBuilder.draftPrompt(chunks: chunks, count: 5);
    expect(prompt, contains('Return ONLY a JSON array'));
    expect(prompt, contains('"answerIndex"'));
    expect(prompt, contains('1, 2'));
  });

  test('online draft prompt uses a JSON object and guards citations', () {
    final prompt = PromptBuilder.draftPrompt(
      chunks: chunks,
      count: 5,
      jsonObject: true,
    );
    expect(prompt, contains('Return ONLY one JSON object'));
    expect(prompt, contains('"questions"'));

    final noContext = PromptBuilder.questionPrompt(
      question: 'What is RA 10175?',
      options: const [
        'Cybercrime law',
        'Wiretapping law',
        'E-commerce law',
        'Data privacy law',
      ],
      answerIndex: 0,
      explanation: 'It is the Cybercrime Prevention Act.',
      chunks: const [],
      citeHandout: false,
    );
    expect(noContext, contains('do not claim a handout citation'));
  });
}
