class TutorAnswer {
  const TutorAnswer({required this.body, required this.source});
  final String body;
  final String source;
}

class TutorService {
  static const bool isSupported = false;

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
  }) async =>
      const TutorAnswer(body: '', source: '');
}
