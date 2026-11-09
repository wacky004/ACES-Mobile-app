import 'package:cpe_reviewer/services/ai/draft_quiz_service.dart';
import 'package:cpe_reviewer/services/ai/rag_index.dart';
import 'package:flutter_test/flutter_test.dart';

RagChunk sourceChunk(int page) => RagChunk(
  id: 'chunk-$page',
  termId: 'pdf',
  handoutId: 'pdf',
  handoutNumber: 'PDF',
  handoutTitle: 'sample.pdf',
  page: page,
  text: 'The Cybercrime Prevention Act of 2012 is Republic Act No. 10175.',
  isPdf: true,
);

void main() {
  test('parses a valid JSON array and rejects malformed items', () {
    final chunks = [sourceChunk(1), sourceChunk(2)];
    const raw = '''
```json
[
  {
    "stem": "Which law is the Cybercrime Prevention Act of 2012?",
    "options": ["RA 10175", "RA 4200", "RA 8792", "RA 8484"],
    "answerIndex": 0,
    "explanation": "It is Republic Act No. 10175.",
    "topic": "Philippine IT laws",
    "difficulty": "easy",
    "sourcePage": 2
  },
  {
    "stem": "Broken item",
    "options": ["A", "B", "C"],
    "answerIndex": 0,
    "explanation": "Only three options.",
    "topic": "Broken",
    "difficulty": "easy",
    "sourcePage": 1
  }
]
```
''';
    final parsed = DraftQuizService().parseQuestions(raw, chunks);
    expect(parsed.length, 1);
    expect(parsed.single.options.length, 4);
    expect(parsed.single.answerIndex, 0);
    expect(parsed.single.sourcePage, 2);
    expect(parsed.single.topic, 'Philippine IT laws');
    expect(parsed.single.difficulty, 'easy');
  });

  test(
    'accepts a wrapped questions object and falls back to a source page',
    () {
      final chunks = [sourceChunk(4)];
      const raw = '''
{"questions": [
  {
    "stem": "What is RA 10175?",
    "options": ["Cybercrime law", "Wiretapping law", "E-commerce law", "Data privacy law"],
    "answerIndex": 0,
    "explanation": "RA 10175 is the Cybercrime Prevention Act.",
    "difficulty": "hard",
    "sourcePage": 99
  }
]}
''';
      final parsed = DraftQuizService().parseQuestions(raw, chunks);
      expect(parsed.length, 1);
      expect(parsed.single.sourcePage, 4);
      expect(parsed.single.difficulty, 'hard');
    },
  );
}
