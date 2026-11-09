import 'rag_index.dart';

class ChatTurn {
  const ChatTurn({required this.isUser, required this.text});
  final bool isUser;
  final String text;
}

class PromptBuilder {
  static const systemPrompt = '''
You are an offline study tutor for Computer Engineering courses.
Answer ONLY from the handout excerpts provided in the user message.
If the answer is not present in the excerpts, say: "This is not covered in the provided handout."
Cite sources exactly like [Handout 02, page 1] or [File.pdf, page 3].
Keep answers concise: at most 180 words, with short paragraphs or bullets.
Do not invent laws, cases, dates, section numbers, or quotations.
Do not give legal advice. Tell the student to verify against the official handout.
''';

  static const deepSeekSystemPrompt = '''
You are a study tutor for Computer Engineering courses.
Answer clearly and accurately. If handout excerpts are provided in the user message, base your answer on those excerpts and cite the handout and page. If no excerpts are provided, answer from the quiz item and general knowledge, and say when you are unsure.
Do not invent laws, cases, dates, or quotations. Do not give legal advice. Keep answers concise.
''';

  static const draftSystemPrompt = '''
You create multiple-choice review questions for a college Computer Engineering course.
Use ONLY facts stated in the provided handout excerpts.
Output ONLY one valid JSON object with a "questions" array. No markdown, no comments, no explanation outside the JSON.
Every question must have exactly 4 unique options and exactly one correct answer.
''';

  static String contextBlock(List<RagChunk> chunks) {
    if (chunks.isEmpty) {
      return 'No handout excerpts were retrieved for this question.';
    }
    final buffer = StringBuffer('HANDOUT EXCERPTS:\n');
    for (var index = 0; index < chunks.length; index++) {
      final chunk = chunks[index];
      final text = chunk.text.length > 900
          ? '${chunk.text.substring(0, 900)}…'
          : chunk.text;
      buffer
        ..writeln('${chunk.promptLabel}:')
        ..writeln(text)
        ..writeln();
    }
    return buffer.toString().trim();
  }

  static String questionPrompt({
    required String question,
    required List<String> options,
    required int answerIndex,
    required String explanation,
    required List<RagChunk> chunks,
    String? topic,
    bool citeHandout = true,
  }) {
    final correct = options.isEmpty
        ? ''
        : '${String.fromCharCode(65 + answerIndex)}. ${options[answerIndex]}';
    final optionsText = StringBuffer();
    for (var index = 0; index < options.length; index++) {
      optionsText.writeln(
        '${String.fromCharCode(65 + index)}. ${options[index]}',
      );
    }
    return '''
${contextBlock(chunks)}

STUDENT'S QUIZ ITEM:
${topic == null ? '' : 'Topic: $topic'}
$question

Options:
${optionsText.toString().trim()}

Correct answer: $correct
Curated explanation: $explanation

${citeHandout ? 'Explain why the correct answer is right, and give one short memory hook. Cite the handout excerpt.' : 'Explain why the correct answer is right, and give one short memory hook. No handout excerpts were shared; do not claim a handout citation, and say when you are unsure.'}
''';
  }

  static String chatPrompt({
    required String userMessage,
    required List<RagChunk> chunks,
    List<ChatTurn> history = const [],
  }) {
    final recent = history.length > 6
        ? history.sublist(history.length - 6)
        : history;
    final historyText = StringBuffer();
    for (final turn in recent) {
      final text = turn.text.length > 300
          ? '${turn.text.substring(0, 300)}…'
          : turn.text;
      historyText.writeln('${turn.isUser ? 'Student' : 'Tutor'}: $text');
    }
    return '''
${contextBlock(chunks)}

${historyText.isEmpty ? '' : 'RECENT CONVERSATION:\n${historyText.toString().trim()}\n'}

STUDENT QUESTION:
$userMessage

Answer from the handout excerpts. Cite handout and page.
''';
  }

  static String draftPrompt({
    required List<RagChunk> chunks,
    required int count,
    bool jsonObject = false,
  }) {
    final pages = chunks.map((chunk) => chunk.page).toSet().join(', ');
    final instructions = jsonObject
        ? 'Return ONLY one JSON object with a "questions" array. '
              'No markdown fences, no commentary.'
        : 'Return ONLY a JSON array. No markdown fences, no commentary.';
    final schema = jsonObject
        ? '''
{
  "questions": [
    {
      "stem": "question text",
      "options": ["option A", "option B", "option C", "option D"],
      "answerIndex": 0,
      "explanation": "why the answer is correct",
      "topic": "short topic label",
      "difficulty": "easy" or "medium" or "hard",
      "sourcePage": one of [$pages]
    }
  ]
}
'''
        : '''
[
  {
    "stem": "question text",
    "options": ["option A", "option B", "option C", "option D"],
    "answerIndex": 0,
    "explanation": "why the answer is correct",
    "topic": "short topic label",
    "difficulty": "easy" or "medium" or "hard",
    "sourcePage": one of [$pages]
  }
]
''';
    return '''
${contextBlock(chunks)}

TASK:
Create exactly $count multiple-choice review questions from the handout excerpts above.
Each question must have exactly 4 options, exactly one correct answer, and a short explanation.
Use only facts stated in the excerpts. Do not invent details.

$instructions
Schema:
$schema
''';
  }
}
