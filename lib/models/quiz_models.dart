import 'subject_pack.dart';

enum QuizMode {
  practice('Practice'),
  exam('Exam');

  const QuizMode(this.label);
  final String label;
}

class QuizConfig {
  const QuizConfig({
    required this.termIds,
    required this.itemCount,
    required this.weights,
    required this.mode,
    this.focusWeakAreas = false,
    this.timerEnabled = false,
    this.difficulty,
    this.questionIds,
  });

  final List<String> termIds;
  final int itemCount;
  final Map<String, int> weights;
  final QuizMode mode;
  final bool focusWeakAreas;
  final bool timerEnabled;
  final Difficulty? difficulty;

  /// When set, the quiz uses exactly these questions (used by retry-wrong).
  final List<String>? questionIds;

  int get secondsPerItem => 60;
  int? get timeLimitSeconds => timerEnabled ? itemCount * secondsPerItem : null;

  QuizConfig copyWith({
    List<String>? termIds,
    int? itemCount,
    Map<String, int>? weights,
    QuizMode? mode,
    bool? focusWeakAreas,
    bool? timerEnabled,
    Difficulty? difficulty,
    List<String>? questionIds,
  }) => QuizConfig(
    termIds: termIds ?? this.termIds,
    itemCount: itemCount ?? this.itemCount,
    weights: weights ?? this.weights,
    mode: mode ?? this.mode,
    focusWeakAreas: focusWeakAreas ?? this.focusWeakAreas,
    timerEnabled: timerEnabled ?? this.timerEnabled,
    difficulty: difficulty ?? this.difficulty,
    questionIds: questionIds ?? this.questionIds,
  );

  Map<String, dynamic> toJson() => {
    'termIds': termIds,
    'itemCount': itemCount,
    'weights': weights,
    'mode': mode.name,
    'focusWeakAreas': focusWeakAreas,
    'timerEnabled': timerEnabled,
    'difficulty': difficulty?.name,
    'questionIds': questionIds,
  };

  factory QuizConfig.fromJson(Map<String, dynamic> json) => QuizConfig(
    termIds: (json['termIds'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false),
    itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
    weights: (json['weights'] as Map<dynamic, dynamic>? ?? const {}).map(
      (key, value) => MapEntry(key.toString(), (value as num).toInt()),
    ),
    mode: json['mode'] == 'exam' ? QuizMode.exam : QuizMode.practice,
    focusWeakAreas: json['focusWeakAreas'] as bool? ?? false,
    timerEnabled: json['timerEnabled'] as bool? ?? false,
    difficulty: json['difficulty'] == null
        ? null
        : Difficulty.parse(json['difficulty']),
    questionIds: json['questionIds'] == null
        ? null
        : (json['questionIds'] as List<dynamic>)
              .map((item) => item.toString())
              .toList(growable: false),
  );
}

class QuizItem {
  QuizItem({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.selectedIndex,
    this.flagged = false,
    this.bookmarked = false,
  });

  final Question question;
  final List<String> options;
  final int correctIndex;
  int? selectedIndex;
  bool flagged;
  bool bookmarked;

  bool get isAnswered => selectedIndex != null;
  bool get isCorrect => selectedIndex == correctIndex;
}

class AttemptItem {
  const AttemptItem({
    required this.questionId,
    required this.termId,
    required this.handoutId,
    required this.topic,
    required this.stem,
    required this.options,
    required this.answerIndex,
    required this.selectedIndex,
    required this.explanation,
    required this.sourcePage,
    required this.difficulty,
    this.type = QuestionType.multipleChoice,
    this.underlined = '',
    this.correction = '',
  });

  final String questionId;
  final String termId;
  final String handoutId;
  final String topic;
  final String stem;
  final List<String> options;
  final int answerIndex;
  final int? selectedIndex;
  final String explanation;
  final int sourcePage;
  final Difficulty difficulty;
  final QuestionType type;
  final String underlined;
  final String correction;

  bool get isCorrect => selectedIndex == answerIndex;
  bool get isModifiedTrueFalse => type == QuestionType.modifiedTrueFalse;

  factory AttemptItem.fromQuizItem(QuizItem item) => AttemptItem(
    questionId: item.question.id,
    termId: item.question.termId,
    handoutId: item.question.handoutId,
    topic: item.question.topic,
    stem: item.question.stem,
    options: item.options,
    answerIndex: item.correctIndex,
    selectedIndex: item.selectedIndex,
    explanation: item.question.explanation,
    sourcePage: item.question.sourcePage,
    difficulty: item.question.difficulty,
    type: item.question.type,
    underlined: item.question.underlined,
    correction: item.question.correction,
  );

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'termId': termId,
    'handoutId': handoutId,
    'topic': topic,
    'stem': stem,
    'options': options,
    'answerIndex': answerIndex,
    'selectedIndex': selectedIndex,
    'explanation': explanation,
    'sourcePage': sourcePage,
    'difficulty': difficulty.name,
    'type': type.name,
    if (underlined.isNotEmpty) 'underlined': underlined,
    if (correction.isNotEmpty) 'correction': correction,
  };

  factory AttemptItem.fromJson(Map<String, dynamic> json) => AttemptItem(
    questionId: json['questionId'] as String,
    termId: json['termId'] as String? ?? '',
    handoutId: json['handoutId'] as String? ?? '',
    topic: json['topic'] as String? ?? 'General',
    stem: json['stem'] as String? ?? '',
    options: (json['options'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false),
    answerIndex: (json['answerIndex'] as num?)?.toInt() ?? 0,
    selectedIndex: (json['selectedIndex'] as num?)?.toInt(),
    explanation: json['explanation'] as String? ?? '',
    sourcePage: (json['sourcePage'] as num?)?.toInt() ?? 1,
    difficulty: Difficulty.parse(json['difficulty']),
    type: QuestionType.parse(json['type']),
    underlined: json['underlined'] as String? ?? '',
    correction: json['correction'] as String? ?? '',
  );
}

class TermResult {
  const TermResult({
    required this.termId,
    required this.correct,
    required this.total,
  });

  final String termId;
  final int correct;
  final int total;
  double get score => total == 0 ? 0 : correct / total;
}

class Attempt {
  const Attempt({
    required this.id,
    required this.subjectId,
    required this.subjectTitle,
    required this.subjectCode,
    required this.startedAt,
    required this.finishedAt,
    required this.config,
    required this.items,
  });

  final String id;
  final String subjectId;
  final String subjectTitle;
  final String subjectCode;
  final DateTime startedAt;
  final DateTime finishedAt;
  final QuizConfig config;
  final List<AttemptItem> items;

  int get total => items.length;
  int get correct => items.where((item) => item.isCorrect).length;
  int get answered => items.where((item) => item.selectedIndex != null).length;
  int get wrong => items
      .where((item) => item.selectedIndex != null && !item.isCorrect)
      .length;
  int get unanswered =>
      items.where((item) => item.selectedIndex == null).length;

  /// Everything that did not earn a point, including unanswered items.
  int get incorrect => total - correct;
  double get score => total == 0 ? 0 : correct / total;
  Duration get duration => finishedAt.difference(startedAt);

  List<TermResult> get termResults {
    final grouped = <String, List<AttemptItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.termId, () => []).add(item);
    }
    return grouped.entries
        .map(
          (entry) => TermResult(
            termId: entry.key,
            correct: entry.value.where((item) => item.isCorrect).length,
            total: entry.value.length,
          ),
        )
        .toList(growable: false);
  }

  double get weightedScore {
    final results = termResults;
    var weightSum = 0.0;
    var weighted = 0.0;
    for (final result in results) {
      final weight = (config.weights[result.termId] ?? 0).toDouble();
      if (weight <= 0) continue;
      weightSum += weight;
      weighted += weight * result.score;
    }
    return weightSum == 0 ? score : weighted / weightSum;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'subjectTitle': subjectTitle,
    'subjectCode': subjectCode,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    'config': config.toJson(),
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory Attempt.fromJson(Map<String, dynamic> json) => Attempt(
    id: json['id'] as String,
    subjectId: json['subjectId'] as String,
    subjectTitle: json['subjectTitle'] as String? ?? '',
    subjectCode: json['subjectCode'] as String? ?? '',
    startedAt:
        DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
    finishedAt:
        DateTime.tryParse(json['finishedAt'] as String? ?? '') ??
        DateTime.now(),
    config: QuizConfig.fromJson(
      (json['config'] as Map<dynamic, dynamic>? ?? const {})
          .cast<String, dynamic>(),
    ),
    items: (json['items'] as List<dynamic>? ?? const [])
        .map(
          (item) => AttemptItem.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList(growable: false),
  );
}

class TermStat {
  const TermStat({
    required this.termId,
    required this.answered,
    required this.correct,
  });

  final String termId;
  final int answered;
  final int correct;
  double get accuracy => answered == 0 ? 0 : correct / answered;
}

class TopicStat {
  const TopicStat({
    required this.key,
    required this.termId,
    required this.topic,
    required this.answered,
    required this.correct,
  });

  final String key;
  final String termId;
  final String topic;
  final int answered;
  final int correct;
  double get accuracy => answered == 0 ? 0 : correct / answered;
}
