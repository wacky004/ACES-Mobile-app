import 'dart:math';

import 'package:cpe_reviewer/models/quiz_models.dart';
import 'package:cpe_reviewer/models/subject_pack.dart';
import 'package:cpe_reviewer/services/quiz_service.dart';
import 'package:flutter_test/flutter_test.dart';

SubjectPack buildTestPack() {
  final questions = <Question>[];
  for (var index = 0; index < 20; index++) {
    final termId = index < 10 ? 'prelim' : 'finals';
    questions.add(
      Question(
        id: 'q$index',
        termId: termId,
        handoutId: termId == 'prelim' ? 'prelim-01' : 'finals-07',
        topic: 'Topic ${index % 4}',
        difficulty: Difficulty.values[index % 3],
        stem: 'Question $index?',
        options: const ['Correct', 'Wrong A', 'Wrong B', 'Wrong C'],
        answerIndex: 0,
        explanation: 'Explanation $index',
        sourcePage: 1,
      ),
    );
  }
  return SubjectPack(
    id: 'test',
    subject: 'Test Subject',
    code: 'TST101',
    org: 'Test Org',
    version: '1.0.0',
    description: '',
    authors: const [],
    license: '',
    terms: const [
      Term(id: 'prelim', name: 'Prelim', order: 1, defaultWeight: 20),
      Term(id: 'finals', name: 'Finals', order: 2, defaultWeight: 40),
    ],
    handouts: const [
      Handout(
        id: 'prelim-01',
        termId: 'prelim',
        number: '01',
        title: 'Prelim handout',
      ),
      Handout(
        id: 'finals-07',
        termId: 'finals',
        number: '07',
        title: 'Finals handout',
      ),
    ],
    questions: questions,
  );
}

void main() {
  group('QuizService.allocate', () {
    test('splits items by weight and keeps the requested total', () {
      final service = QuizService(random: Random(1));
      final allocation = service.allocate(
        count: 30,
        termIds: const ['prelim', 'finals'],
        weights: const {'prelim': 20, 'finals': 40},
      );
      expect(allocation.values.fold<int>(0, (a, b) => a + b), 30);
      expect(allocation['prelim'], 10);
      expect(allocation['finals'], 20);
    });

    test('gives every term at least one item when count allows', () {
      final service = QuizService(random: Random(1));
      final allocation = service.allocate(
        count: 4,
        termIds: const ['a', 'b', 'c', 'd'],
        weights: const {'a': 1, 'b': 1, 'c': 1, 'd': 1},
      );
      expect(allocation.length, 4);
      expect(allocation.values.every((value) => value >= 1), isTrue);
      expect(allocation.values.fold<int>(0, (a, b) => a + b), 4);
    });

    test('handles fewer items than selected terms', () {
      final service = QuizService(random: Random(1));
      final allocation = service.allocate(
        count: 2,
        termIds: const ['prelim', 'midterm', 'prefinals', 'finals'],
        weights: const {
          'prelim': 20,
          'midterm': 20,
          'prefinals': 20,
          'finals': 40,
        },
      );
      expect(allocation.values.fold<int>(0, (a, b) => a + b), 2);
      expect(allocation['finals'], 1);
      expect(allocation.length, 2);
    });
  });

  group('QuizService.buildQuiz', () {
    test('builds the requested number of unique items', () {
      final service = QuizService(random: Random(7));
      final pack = buildTestPack();
      final result = service.buildQuiz(
        pack: pack,
        config: const QuizConfig(
          termIds: ['prelim', 'finals'],
          itemCount: 15,
          weights: {'prelim': 20, 'finals': 40},
          mode: QuizMode.practice,
        ),
      );
      expect(result.items.length, 15);
      expect(result.config.itemCount, 15);
      expect(result.items.map((item) => item.question.id).toSet().length, 15);
      for (final item in result.items) {
        expect(item.options.length, 4);
        expect(item.options[item.correctIndex], 'Correct');
      }
    });

    test('clamps to available questions', () {
      final service = QuizService(random: Random(3));
      final pack = buildTestPack();
      final result = service.buildQuiz(
        pack: pack,
        config: const QuizConfig(
          termIds: ['prelim'],
          itemCount: 50,
          weights: {'prelim': 20},
          mode: QuizMode.exam,
        ),
      );
      expect(result.items.length, 10);
      expect(result.config.itemCount, 10);
    });

    test('builds retry quizzes from question ids', () {
      final service = QuizService(random: Random(3));
      final pack = buildTestPack();
      final first = service.buildQuiz(
        pack: pack,
        config: const QuizConfig(
          termIds: ['prelim'],
          itemCount: 5,
          weights: {'prelim': 20},
          mode: QuizMode.practice,
        ),
      );
      final ids = first.items.map((item) => item.question.id).toList();
      final retry = service.buildQuiz(
        pack: pack,
        config: QuizConfig(
          termIds: const ['prelim'],
          itemCount: ids.length,
          weights: const {'prelim': 20},
          mode: QuizMode.practice,
          questionIds: ids,
        ),
      );
      expect(retry.items.length, ids.length);
      expect(retry.items.map((item) => item.question.id).toSet(), ids.toSet());
    });
  });

  test('weighted attempt score follows configured weights', () {
    final attempt = Attempt(
      id: 'a1',
      subjectId: 'test',
      subjectTitle: 'Test Subject',
      subjectCode: 'TST101',
      startedAt: DateTime(2026, 1, 1, 8),
      finishedAt: DateTime(2026, 1, 1, 8, 10),
      config: const QuizConfig(
        termIds: ['prelim', 'finals'],
        itemCount: 10,
        weights: {'prelim': 20, 'finals': 40},
        mode: QuizMode.exam,
      ),
      items: [
        for (var index = 0; index < 4; index++)
          AttemptItem(
            questionId: 'p$index',
            termId: 'prelim',
            handoutId: 'prelim-01',
            topic: 'Topic',
            stem: 'Stem',
            options: const ['Answer', 'B', 'C', 'D'],
            answerIndex: 0,
            selectedIndex: index < 2 ? 0 : 1,
            explanation: 'Explanation',
            sourcePage: 1,
            difficulty: Difficulty.easy,
          ),
        for (var index = 0; index < 6; index++)
          AttemptItem(
            questionId: 'f$index',
            termId: 'finals',
            handoutId: 'finals-07',
            topic: 'Topic',
            stem: 'Stem',
            options: const ['Answer', 'B', 'C', 'D'],
            answerIndex: 0,
            selectedIndex: 0,
            explanation: 'Explanation',
            sourcePage: 1,
            difficulty: Difficulty.medium,
          ),
      ],
    );

    expect(attempt.score, closeTo(0.8, 0.0001));
    expect(attempt.weightedScore, closeTo(0.8333333, 0.0001));
    expect(attempt.wrong, 2);
    expect(attempt.unanswered, 0);
    expect(attempt.incorrect, 2);
    final retry = QuizService().retryWrongConfig(attempt);
    expect(retry.questionIds, ['p2', 'p3']);
    expect(retry.itemCount, 2);
    expect(retry.mode, QuizMode.practice);
  });

  test('modified true/false keeps True then False order', () {
    final pack = SubjectPack(
      id: 'tf',
      subject: 'T/F Subject',
      code: 'TF',
      org: 'Test',
      version: '1.0.0',
      description: '',
      authors: const [],
      license: '',
      terms: const [
        Term(id: 'prelim', name: 'Prelim', order: 1, defaultWeight: 100),
      ],
      handouts: const [
        Handout(
          id: 'prelim-01',
          termId: 'prelim',
          number: '01',
          title: 'Handout',
        ),
      ],
      questions: [
        const Question(
          id: 'tf1',
          termId: 'prelim',
          handoutId: 'prelim-01',
          topic: 'T/F',
          difficulty: Difficulty.easy,
          stem: 'The setup() function runs only once.',
          options: ['True', 'False'],
          answerIndex: 1,
          explanation: 'setup() runs once.',
          sourcePage: 1,
          type: QuestionType.modifiedTrueFalse,
          underlined: 'only once',
          correction: 'repeatedly',
        ),
      ],
    );
    final result = QuizService(random: Random(1)).buildQuiz(
      pack: pack,
      config: const QuizConfig(
        termIds: ['prelim'],
        itemCount: 1,
        weights: {'prelim': 100},
        mode: QuizMode.practice,
      ),
    );
    expect(result.items.single.options, ['True', 'False']);
    expect(result.items.single.correctIndex, 1);
  });

  test('fresh items are preferred before recent questions', () {
    final pack = buildTestPack();
    final service = QuizService(random: Random(11));
    final config = const QuizConfig(
      termIds: ['prelim'],
      itemCount: 5,
      weights: {'prelim': 100},
      mode: QuizMode.practice,
    );
    final first = service.buildQuiz(pack: pack, config: config);
    final attempt = service.createAttempt(
      subject: pack,
      config: first.config,
      items: first.items,
      startedAt: DateTime(2026, 1, 1, 8),
    );
    final second = service.buildQuiz(
      pack: pack,
      config: config,
      history: [attempt],
    );
    final firstIds = first.items.map((item) => item.question.id).toSet();
    final secondIds = second.items.map((item) => item.question.id).toSet();
    expect(firstIds.intersection(secondIds), isEmpty);
  });
}
