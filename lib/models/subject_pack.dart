import 'dart:convert';

enum QuestionType {
  multipleChoice('Multiple choice'),
  modifiedTrueFalse('Modified True/False');

  const QuestionType(this.label);
  final String label;

  static QuestionType parse(Object? value) {
    final normalized =
        value?.toString().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '') ?? '';
    if (normalized == 'modifiedtruefalse' ||
        normalized == 'truefalse' ||
        normalized == 'tf') {
      return QuestionType.modifiedTrueFalse;
    }
    return QuestionType.multipleChoice;
  }
}

enum Difficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');

  const Difficulty(this.label);
  final String label;

  static Difficulty parse(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'easy':
        return Difficulty.easy;
      case 'hard':
        return Difficulty.hard;
      default:
        return Difficulty.medium;
    }
  }
}

class Term {
  const Term({
    required this.id,
    required this.name,
    required this.order,
    required this.defaultWeight,
  });

  final String id;
  final String name;
  final int order;
  final int defaultWeight;

  factory Term.fromJson(Map<String, dynamic> json) => Term(
    id: json['id'] as String,
    name: json['name'] as String,
    order: (json['order'] as num?)?.toInt() ?? 0,
    defaultWeight: (json['defaultWeight'] as num?)?.toInt() ?? 25,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'order': order,
    'defaultWeight': defaultWeight,
  };
}

class Handout {
  const Handout({
    required this.id,
    required this.termId,
    required this.number,
    required this.title,
  });

  final String id;
  final String termId;
  final String number;
  final String title;

  factory Handout.fromJson(Map<String, dynamic> json) => Handout(
    id: json['id'] as String,
    termId: json['termId'] as String,
    number: json['number'] as String? ?? '',
    title: json['title'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'termId': termId,
    'number': number,
    'title': title,
  };
}

class Question {
  const Question({
    required this.id,
    required this.termId,
    required this.handoutId,
    required this.topic,
    required this.difficulty,
    required this.stem,
    required this.options,
    required this.answerIndex,
    required this.explanation,
    required this.sourcePage,
    this.type = QuestionType.multipleChoice,
    this.underlined = '',
    this.correction = '',
  });

  final String id;
  final String termId;
  final String handoutId;
  final String topic;
  final Difficulty difficulty;
  final String stem;
  final List<String> options;
  final int answerIndex;
  final String explanation;
  final int sourcePage;
  final QuestionType type;
  final String underlined;
  final String correction;

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'] as String,
    termId: json['termId'] as String? ?? json['term'] as String? ?? '',
    handoutId: json['handoutId'] as String? ?? json['handout'] as String? ?? '',
    topic: json['topic'] as String? ?? 'General',
    difficulty: Difficulty.parse(json['difficulty']),
    stem: json['stem'] as String? ?? json['question'] as String? ?? '',
    options: (json['options'] as List<dynamic>)
        .map((option) => option.toString())
        .toList(growable: false),
    answerIndex:
        (json['answerIndex'] as num?)?.toInt() ??
        (json['answer'] as num?)?.toInt() ??
        0,
    explanation: json['explanation'] as String? ?? '',
    sourcePage: (json['sourcePage'] as num?)?.toInt() ?? 1,
    type: QuestionType.parse(json['type']),
    underlined: json['underlined'] as String? ?? '',
    correction: json['correction'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'termId': termId,
    'handoutId': handoutId,
    'topic': topic,
    'difficulty': difficulty.name,
    'type': type.name,
    'stem': stem,
    'options': options,
    'answerIndex': answerIndex,
    if (underlined.trim().isNotEmpty) 'underlined': underlined,
    if (correction.trim().isNotEmpty) 'correction': correction,
    'explanation': explanation,
    'sourcePage': sourcePage,
  };

  bool get isModifiedTrueFalse => type == QuestionType.modifiedTrueFalse;

  String get correctOption => options[answerIndex];
}

class SubjectPack {
  const SubjectPack({
    required this.id,
    required this.subject,
    required this.code,
    required this.org,
    required this.version,
    required this.description,
    required this.authors,
    required this.license,
    required this.terms,
    required this.handouts,
    required this.questions,
  });

  final String id;
  final String subject;
  final String code;
  final String org;
  final String version;
  final String description;
  final List<String> authors;
  final String license;
  final List<Term> terms;
  final List<Handout> handouts;
  final List<Question> questions;

  factory SubjectPack.fromJson(Map<String, dynamic> json) {
    final questions = (json['questions'] as List<dynamic>? ?? const [])
        .map((item) => Question.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    final terms =
        (json['terms'] as List<dynamic>? ?? const [])
            .map((item) => Term.fromJson(item as Map<String, dynamic>))
            .toList(growable: false)
          ..sort((a, b) => a.order.compareTo(b.order));
    final handouts = (json['handouts'] as List<dynamic>? ?? const [])
        .map((item) => Handout.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    return SubjectPack(
      id: json['id'] as String,
      subject: json['subject'] as String? ?? json['title'] as String? ?? '',
      code: json['code'] as String? ?? '',
      org: json['org'] as String? ?? '',
      version: json['version'] as String? ?? '1.0.0',
      description: json['description'] as String? ?? '',
      authors: (json['authors'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      license: json['license'] as String? ?? '',
      terms: terms,
      handouts: handouts,
      questions: questions,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject,
    'code': code,
    'org': org,
    'version': version,
    'description': description,
    'authors': authors,
    'license': license,
    'terms': terms.map((term) => term.toJson()).toList(),
    'handouts': handouts.map((handout) => handout.toJson()).toList(),
    'questions': questions.map((question) => question.toJson()).toList(),
  };

  Handout? handoutById(String id) {
    for (final handout in handouts) {
      if (handout.id == id) return handout;
    }
    return null;
  }

  Term? termById(String id) {
    for (final term in terms) {
      if (term.id == id) return term;
    }
    return null;
  }

  Map<String, int> get defaultWeights => {
    for (final term in terms) term.id: term.defaultWeight,
  };

  int questionsForTerm(String termId) =>
      questions.where((question) => question.termId == termId).length;

  List<Question> questionsForTerms(Set<String> termIds) => questions
      .where((question) => termIds.contains(question.termId))
      .toList(growable: false);

  /// Returns a list of human-readable problems. An empty list means valid.
  static List<String> validate(SubjectPack pack) {
    final problems = <String>[];
    if (pack.id.trim().isEmpty) problems.add('Pack id is missing.');
    if (pack.subject.trim().isEmpty) problems.add('Subject title is missing.');
    if (pack.terms.isEmpty) problems.add('No terms defined.');
    if (pack.questions.isEmpty) problems.add('No questions found.');

    final termIds = <String>{};
    for (final term in pack.terms) {
      if (!termIds.add(term.id)) {
        problems.add('Duplicate term id: ${term.id}');
      }
      if (term.defaultWeight < 0) {
        problems.add('Negative weight for term ${term.id}');
      }
    }

    final handoutIds = <String>{};
    for (final handout in pack.handouts) {
      if (!handoutIds.add(handout.id)) {
        problems.add('Duplicate handout id: ${handout.id}');
      }
      if (!termIds.contains(handout.termId)) {
        problems.add(
          'Handout ${handout.id} references unknown term ${handout.termId}',
        );
      }
    }

    final questionIds = <String>{};
    for (final question in pack.questions) {
      if (!questionIds.add(question.id)) {
        problems.add('Duplicate question id: ${question.id}');
      }
      if (!termIds.contains(question.termId)) {
        problems.add(
          'Question ${question.id} references unknown term ${question.termId}',
        );
      }
      if (!handoutIds.contains(question.handoutId)) {
        problems.add(
          'Question ${question.id} references unknown handout ${question.handoutId}',
        );
      }
      if (question.isModifiedTrueFalse) {
        if (question.options.length != 2 ||
            question.options[0].toLowerCase() != 'true' ||
            question.options[1].toLowerCase() != 'false') {
          problems.add(
            'Question ${question.id} must use True/False options in that order.',
          );
        }
        if (question.answerIndex != 0 && question.answerIndex != 1) {
          problems.add(
            'Question ${question.id} has an invalid True/False answer.',
          );
        }
        if (question.underlined.trim().isEmpty ||
            !question.stem.contains(question.underlined)) {
          problems.add(
            'Question ${question.id} must underline a phrase that appears in the stem.',
          );
        }
        if (question.answerIndex == 1 && question.correction.trim().isEmpty) {
          problems.add(
            'Question ${question.id} needs a correction for a false statement.',
          );
        }
      } else {
        if (question.options.length != 4) {
          problems.add('Question ${question.id} must have exactly 4 options.');
        }
        if (question.answerIndex < 0 ||
            question.answerIndex >= question.options.length) {
          problems.add('Question ${question.id} has an invalid answer index.');
        }
      }
      if (question.stem.trim().isEmpty) {
        problems.add('Question ${question.id} has an empty stem.');
      }
      if (question.explanation.trim().isEmpty) {
        problems.add('Question ${question.id} has no explanation.');
      }
    }
    return problems;
  }

  /// Parses a full pack or a question-only merge document.
  static bool isFullPackJson(Map<String, dynamic> json) =>
      json['id'] != null && json['terms'] is List;

  static List<Question> parseQuestionList(Map<String, dynamic> json) =>
      (json['questions'] as List<dynamic>? ?? const [])
          .map((item) => Question.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);

  static SubjectPack mergeQuestions(
    SubjectPack existing,
    Map<String, dynamic> json,
  ) {
    final incoming = parseQuestionList(json);
    final merged = <String, Question>{
      for (final question in existing.questions) question.id: question,
      for (final question in incoming) question.id: question,
    };
    return SubjectPack(
      id: existing.id,
      subject: existing.subject,
      code: existing.code,
      org: existing.org,
      version: json['version'] as String? ?? existing.version,
      description: existing.description,
      authors: existing.authors,
      license: existing.license,
      terms: existing.terms,
      handouts: existing.handouts,
      questions: merged.values.toList(growable: false),
    );
  }
}

String encodePack(SubjectPack pack) =>
    const JsonEncoder.withIndent('  ').convert(pack.toJson());
