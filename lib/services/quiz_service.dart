import 'dart:math';

import '../models/quiz_models.dart';
import '../models/subject_pack.dart';

class QuizBuildResult {
  const QuizBuildResult({required this.items, required this.config});
  final List<QuizItem> items;
  final QuizConfig config;
}

class QuizService {
  QuizService({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Splits [count] across [termIds] using the supplied weights.
  /// Every selected term gets at least one item when possible.
  Map<String, int> allocate({
    required int count,
    required List<String> termIds,
    required Map<String, int> weights,
  }) {
    final terms = termIds.toSet().toList(growable: false);
    if (count <= 0 || terms.isEmpty) return {};

    final positive = <String, int>{
      for (final id in terms)
        if ((weights[id] ?? 0) > 0) id: weights[id]!,
    };
    final effective = positive.isEmpty
        ? {for (final id in terms) id: 1}
        : positive;

    if (count < effective.length) {
      final ordered = effective.entries.toList()
        ..sort((a, b) {
          final byWeight = b.value.compareTo(a.value);
          if (byWeight != 0) return byWeight;
          return terms.indexOf(a.key).compareTo(terms.indexOf(b.key));
        });
      return {for (final entry in ordered.take(count)) entry.key: 1};
    }

    final totalWeight = effective.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final remaining = count - effective.length;
    final exact = <String, double>{
      for (final entry in effective.entries)
        entry.key: remaining * entry.value / totalWeight,
    };
    final allocation = <String, int>{
      for (final entry in effective.entries)
        entry.key: 1 + exact[entry.key]!.floor(),
    };
    var leftover = count - allocation.values.fold<int>(0, (a, b) => a + b);

    final order = effective.keys.toList(growable: false);
    final orderIndex = {for (var i = 0; i < order.length; i++) order[i]: i};
    order.sort((a, b) {
      final fractionCompare = (exact[b]! - exact[b]!.floorToDouble()).compareTo(
        exact[a]! - exact[a]!.floorToDouble(),
      );
      if (fractionCompare != 0) return fractionCompare;
      final byWeight = effective[b]!.compareTo(effective[a]!);
      if (byWeight != 0) return byWeight;
      return orderIndex[a]!.compareTo(orderIndex[b]!);
    });
    var index = 0;
    while (leftover > 0) {
      allocation[order[index % order.length]] =
          allocation[order[index % order.length]]! + 1;
      leftover--;
      index++;
    }
    return allocation;
  }

  QuizBuildResult buildQuiz({
    required SubjectPack pack,
    required QuizConfig config,
    List<Attempt> history = const [],
    Set<String> bookmarks = const {},
  }) {
    if (config.questionIds != null && config.questionIds!.isNotEmpty) {
      return _buildFromIds(
        pack: pack,
        config: config,
        history: history,
        bookmarks: bookmarks,
      );
    }

    final selectedTerms = config.termIds
        .where((id) => pack.termById(id) != null)
        .toList(growable: false);
    var targetCount = config.itemCount;
    if (selectedTerms.isEmpty || targetCount <= 0) {
      return QuizBuildResult(
        items: const [],
        config: config.copyWith(itemCount: 0),
      );
    }

    final pools = <String, List<Question>>{};
    for (final termId in selectedTerms) {
      pools[termId] = pack.questions
          .where(
            (question) =>
                question.termId == termId &&
                (config.difficulty == null ||
                    question.difficulty == config.difficulty),
          )
          .toList(growable: false);
    }

    var available = pools.values.fold<int>(0, (sum, pool) => sum + pool.length);
    if (available == 0 && config.difficulty != null) {
      for (final termId in selectedTerms) {
        pools[termId] = pack.questions
            .where((question) => question.termId == termId)
            .toList(growable: false);
      }
      available = pools.values.fold<int>(0, (sum, pool) => sum + pool.length);
      targetCount = config.itemCount;
    }
    if (available == 0) {
      return QuizBuildResult(
        items: const [],
        config: config.copyWith(itemCount: 0),
      );
    }
    if (targetCount > available) targetCount = available;

    final requested = allocate(
      count: targetCount,
      termIds: selectedTerms,
      weights: config.weights,
    );
    final take = <String, int>{for (final termId in selectedTerms) termId: 0};
    for (final entry in requested.entries) {
      take[entry.key] = min(entry.value, pools[entry.key]!.length);
    }

    var assigned = take.values.fold<int>(0, (sum, value) => sum + value);
    while (assigned < targetCount) {
      String? bestTerm;
      var bestWeight = -1;
      for (final termId in selectedTerms) {
        if (take[termId]! >= pools[termId]!.length) continue;
        final weight = config.weights[termId] ?? 1;
        if (weight > bestWeight) {
          bestWeight = weight;
          bestTerm = termId;
        }
      }
      if (bestTerm == null) break;
      take[bestTerm] = take[bestTerm]! + 1;
      assigned++;
    }

    final topicMastery = _topicMastery(history);
    final selectedQuestions = <Question>[];
    for (final termId in selectedTerms) {
      final count = take[termId] ?? 0;
      if (count <= 0) continue;
      final pool = [...pools[termId]!];
      final lastSeen = <String, int>{};
      for (
        var attemptIndex = 0;
        attemptIndex < history.length;
        attemptIndex++
      ) {
        for (final item in history[attemptIndex].items) {
          lastSeen.putIfAbsent(item.questionId, () => attemptIndex);
        }
      }
      final jitter = <Question, double>{
        for (final q in pool) q: _random.nextDouble(),
      };
      pool.sort((a, b) {
        final aSeen = lastSeen[a.id];
        final bSeen = lastSeen[b.id];
        if (aSeen == null && bSeen != null) return -1;
        if (aSeen != null && bSeen == null) return 1;
        if (aSeen != null && bSeen != null && aSeen != bSeen) {
          return bSeen.compareTo(aSeen);
        }
        if (config.focusWeakAreas) {
          final aKey = '${a.handoutId}|${a.topic}';
          final bKey = '${b.handoutId}|${b.topic}';
          final aMastery = topicMastery[aKey] ?? 0;
          final bMastery = topicMastery[bKey] ?? 0;
          final byMastery = aMastery.compareTo(bMastery);
          if (byMastery != 0) return byMastery;
        }
        return jitter[a]!.compareTo(jitter[b]!);
      });
      selectedQuestions.addAll(pool.take(count));
    }

    selectedQuestions.shuffle(_random);
    final items = selectedQuestions
        .map(
          (question) => _toQuizItem(
            question,
            bookmarked: bookmarks.contains(question.id),
          ),
        )
        .toList(growable: false);

    return QuizBuildResult(
      items: items,
      config: config.copyWith(
        termIds: selectedTerms,
        itemCount: items.length,
        questionIds: null,
      ),
    );
  }

  QuizBuildResult _buildFromIds({
    required SubjectPack pack,
    required QuizConfig config,
    required List<Attempt> history,
    required Set<String> bookmarks,
  }) {
    final byId = {for (final question in pack.questions) question.id: question};
    final selected = <Question>[];
    for (final id in config.questionIds!) {
      final question = byId[id];
      if (question != null) selected.add(question);
    }
    selected.shuffle(_random);
    final items = selected
        .map(
          (question) => _toQuizItem(
            question,
            bookmarked: bookmarks.contains(question.id),
          ),
        )
        .toList(growable: false);
    final terms = items.map((item) => item.question.termId).toSet().toList();
    return QuizBuildResult(
      items: items,
      config: config.copyWith(
        termIds: terms,
        itemCount: items.length,
        questionIds: config.questionIds,
      ),
    );
  }

  QuizItem _toQuizItem(Question question, {required bool bookmarked}) {
    if (question.isModifiedTrueFalse) {
      return QuizItem(
        question: question,
        options: question.options,
        correctIndex: question.answerIndex,
        bookmarked: bookmarked,
      );
    }
    final indices = List<int>.generate(
      question.options.length,
      (index) => index,
    )..shuffle(_random);
    final options = indices
        .map((index) => question.options[index])
        .toList(growable: false);
    final correctIndex = indices.indexOf(question.answerIndex);
    return QuizItem(
      question: question,
      options: options,
      correctIndex: correctIndex,
      bookmarked: bookmarked,
    );
  }

  Map<String, double> _topicMastery(List<Attempt> history) {
    final answered = <String, int>{};
    final correct = <String, int>{};
    for (final attempt in history) {
      for (final item in attempt.items) {
        final key = '${item.handoutId}|${item.topic}';
        answered[key] = (answered[key] ?? 0) + 1;
        if (item.isCorrect) correct[key] = (correct[key] ?? 0) + 1;
      }
    }
    return {
      for (final entry in answered.entries)
        entry.key: (correct[entry.key] ?? 0) / entry.value,
    };
  }

  Attempt createAttempt({
    required SubjectPack subject,
    required QuizConfig config,
    required List<QuizItem> items,
    required DateTime startedAt,
  }) {
    final finishedAt = DateTime.now();
    return Attempt(
      id: '${finishedAt.microsecondsSinceEpoch}-${_random.nextInt(1 << 31)}',
      subjectId: subject.id,
      subjectTitle: subject.subject,
      subjectCode: subject.code,
      startedAt: startedAt,
      finishedAt: finishedAt,
      config: config,
      items: items.map(AttemptItem.fromQuizItem).toList(growable: false),
    );
  }

  QuizConfig retryWrongConfig(Attempt attempt) {
    final wrong = attempt.items
        .where((item) => !item.isCorrect)
        .map((item) => item.questionId)
        .toList(growable: false);
    return QuizConfig(
      termIds: attempt.items.map((item) => item.termId).toSet().toList(),
      itemCount: wrong.length,
      weights: attempt.config.weights,
      mode: QuizMode.practice,
      difficulty: attempt.config.difficulty,
      questionIds: wrong,
    );
  }
}

double normalizeWeightPercent(int value, Map<String, int> weights) {
  final total = weights.values.fold<int>(0, (sum, item) => sum + item);
  if (total <= 0) return 0;
  return value / total;
}
