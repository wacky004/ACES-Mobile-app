class TutorAnswer {
  const TutorAnswer({required this.body, required this.source});
  final String body;
  final String source;
}

class TutorService {
  static const bool isSupported = true;

  static Future<TutorAnswer> explain({
    required String subjectTitle,
    required String stem,
    required List<String> options,
    required int answerIndex,
    required String explanation,
    required String topic,
    required String handoutTitle,
    required int sourcePage,
    required String difficulty,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final answer = options[answerIndex];
    final studyTip = switch (difficulty.toLowerCase()) {
      'easy' =>
        'Recall this definition without looking at the options before your next attempt.',
      'hard' =>
        'Re-read this section of the handout and connect it to one real case or example.',
      _ =>
        'Cover the options and explain this concept in your own words, then check the handout.',
    };
    final body =
        'Correct answer: $answer\n\n'
        'Why: $explanation\n\n'
        'Remember: $studyTip';
    return TutorAnswer(
      body: body,
      source: '$handoutTitle, page $sourcePage · $topic',
    );
  }
}
