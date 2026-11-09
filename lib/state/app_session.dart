import 'package:flutter/foundation.dart';

import '../data/attempt_repository.dart';
import '../data/bookmark_repository.dart';
import '../data/pack_repository.dart';
import '../data/settings_controller.dart';
import '../models/quiz_models.dart';
import '../models/subject_pack.dart';

class AppSession extends ChangeNotifier {
  AppSession({
    required this.packRepository,
    required this.attemptRepository,
    required this.bookmarkRepository,
    required this.settings,
    required this.packs,
    required this.subject,
  });

  final PackRepository packRepository;
  final AttemptRepository attemptRepository;
  final BookmarkRepository bookmarkRepository;
  final SettingsController settings;
  final List<SubjectPack> packs;

  SubjectPack subject;
  List<Attempt> attempts = const [];
  Set<String> bookmarks = <String>{};

  Future<void> initialize() async {
    await _reload();
  }

  Future<void> selectSubject(String id) async {
    final next = packs.where((pack) => pack.id == id);
    if (next.isEmpty) return;
    if (next.first.id == subject.id) return;
    subject = next.first;
    await settings.setLastSubject(subject.id);
    await _reload();
  }

  Future<void> refresh() => _reload();

  Future<void> reloadPacks() async {
    final loaded = await packRepository.loadAll();
    packs
      ..clear()
      ..addAll(loaded);
    if (!packs.any((pack) => pack.id == subject.id) && packs.isNotEmpty) {
      subject = packs.first;
    }
    await _reload();
  }

  Future<void> _reload() async {
    attempts = await attemptRepository.forSubject(subject.id);
    bookmarks = await bookmarkRepository.idsForSubject(subject.id);
    notifyListeners();
  }

  Future<void> recordAttempt(Attempt attempt) async {
    await attemptRepository.save(attempt);
    attempts = [attempt, ...attempts];
    notifyListeners();
  }

  Future<void> toggleBookmark(String questionId) async {
    final added = await bookmarkRepository.toggle(subject.id, questionId);
    if (added) {
      bookmarks = {...bookmarks, questionId};
    } else {
      bookmarks = {...bookmarks}..remove(questionId);
    }
    notifyListeners();
  }

  Future<void> clearProgress() async {
    await attemptRepository.deleteForSubject(subject.id);
    await bookmarkRepository.clearForSubject(subject.id);
    attempts = const [];
    bookmarks = <String>{};
    notifyListeners();
  }

  Map<String, TermStat> get termStats {
    final answered = <String, int>{};
    final correct = <String, int>{};
    for (final attempt in attempts) {
      for (final item in attempt.items) {
        answered[item.termId] = (answered[item.termId] ?? 0) + 1;
        if (item.isCorrect) {
          correct[item.termId] = (correct[item.termId] ?? 0) + 1;
        }
      }
    }
    return {
      for (final term in subject.terms)
        term.id: TermStat(
          termId: term.id,
          answered: answered[term.id] ?? 0,
          correct: correct[term.id] ?? 0,
        ),
    };
  }

  TermStat termStat(String termId) =>
      termStats[termId] ??
      TermStat(termId: termId, answered: 0, correct: 0);

  double termMastery(String termId) => termStat(termId).accuracy;

  int get answeredCount =>
      termStats.values.fold<int>(0, (sum, stat) => sum + stat.answered);

  int get correctCount =>
      termStats.values.fold<int>(0, (sum, stat) => sum + stat.correct);

  double get accuracy =>
      answeredCount == 0 ? 0 : correctCount / answeredCount;

  double get weightedMastery {
    final weights = settings.weightsFor(subject);
    var weightSum = 0.0;
    var weighted = 0.0;
    for (final term in subject.terms) {
      final stat = termStats[term.id];
      if (stat == null || stat.answered == 0) continue;
      final weight = (weights[term.id] ?? 0).toDouble();
      if (weight <= 0) continue;
      weightSum += weight;
      weighted += weight * stat.accuracy;
    }
    return weightSum == 0 ? 0 : weighted / weightSum;
  }

  List<TopicStat> get topicStats {
    final answered = <String, int>{};
    final correct = <String, int>{};
    final termByKey = <String, String>{};
    final topicByKey = <String, String>{};
    for (final attempt in attempts) {
      for (final item in attempt.items) {
        final key = '${item.handoutId}|${item.topic}';
        answered[key] = (answered[key] ?? 0) + 1;
        if (item.isCorrect) correct[key] = (correct[key] ?? 0) + 1;
        termByKey[key] = item.termId;
        topicByKey[key] = item.topic;
      }
    }
    return [
      for (final key in answered.keys)
        TopicStat(
          key: key,
          termId: termByKey[key]!,
          topic: topicByKey[key]!,
          answered: answered[key]!,
          correct: correct[key] ?? 0,
        ),
    ];
  }

  List<TopicStat> get weakTopics {
    final stats = topicStats.where((stat) => stat.answered > 0).toList();
    stats.sort((a, b) {
      final byAccuracy = a.accuracy.compareTo(b.accuracy);
      if (byAccuracy != 0) return byAccuracy;
      return b.answered.compareTo(a.answered);
    });
    return stats;
  }

  String termName(String termId) =>
      subject.termById(termId)?.name ?? termId;

  String handoutTitle(String handoutId) {
    final handout = subject.handoutById(handoutId);
    if (handout == null) return 'Handout';
    return handout.title.isEmpty
        ? 'Handout ${handout.number}'
        : 'Handout ${handout.number}: ${handout.title}';
  }

  int get totalQuestions => subject.questions.length;

  int get availableQuestions => subject.questions.length;

  QuizConfig defaultConfig({
    List<String>? termIds,
    int itemCount = 30,
    bool focusWeakAreas = false,
  }) {
    final selected = termIds ?? subject.terms.map((term) => term.id).toList();
    return QuizConfig(
      termIds: selected,
      itemCount: itemCount,
      weights: settings.weightsFor(subject),
      mode: QuizMode.practice,
      focusWeakAreas: focusWeakAreas,
    );
  }
}
