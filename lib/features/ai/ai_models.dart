class AiQuestionRequest {
  const AiQuestionRequest({
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.explanation,
    required this.topic,
    required this.handoutTitle,
    required this.sourcePage,
  });

  final String question;
  final List<String> options;
  final int answerIndex;
  final String explanation;
  final String topic;
  final String handoutTitle;
  final int sourcePage;
}
