import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';
import '../services/tutor_service.dart';
import '../state/app_scope.dart';
import '../widgets/question_stem.dart';
import '../widgets/score_ring.dart';
import '../widgets/tutor_sheet.dart';
import '../widgets/ui_kit.dart';
import 'quiz_screen.dart';
import 'quiz_setup_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.attempt,
    this.reviewOnly = false,
    this.autoSubmitted = false,
  });

  final Attempt attempt;
  final bool reviewOnly;
  final bool autoSubmitted;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final session = scope.session;
    final showTutor = TutorService.isSupported && scope.settings.tutorEnabled;
    final passed = attempt.score >= 0.75;
    final termOrder = {
      for (var index = 0; index < session.subject.terms.length; index++)
        session.subject.terms[index].id: index,
    };
    final termResults = [...attempt.termResults]
      ..sort(
        (a, b) =>
            (termOrder[a.termId] ?? 999).compareTo(termOrder[b.termId] ?? 999),
      );

    return Scaffold(
      appBar: AppBar(title: Text(reviewOnly ? 'Attempt review' : 'Results')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (autoSubmitted)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.timer_off_outlined,
                            size: 17,
                            color: AppColors.amber,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Time expired. Your answers were submitted '
                              'automatically.',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _ResultsHero(attempt: attempt, passed: passed),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: MetricTile(
                          label: 'Correct',
                          value: '${attempt.correct}',
                          icon: Icons.check_rounded,
                          accent: AppColors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricTile(
                          label: 'Wrong',
                          value: '${attempt.wrong}',
                          icon: Icons.close_rounded,
                          accent: AppColors.red,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: MetricTile(
                          label: 'Unanswered',
                          value: '${attempt.unanswered}',
                          icon: Icons.remove_rounded,
                          accent: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  if (termResults.length > 1) ...[
                    const SizedBox(height: 22),
                    const SectionHeader(
                      title: 'By term',
                      subtitle: 'Weighted score uses your grading weights.',
                    ),
                    const SizedBox(height: 12),
                    _TermBreakdown(
                      termResults: termResults,
                      termName: session.termName,
                    ),
                  ],
                  const SizedBox(height: 22),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (attempt.incorrect > 0) ...[
                        FilledButton.icon(
                          onPressed: () => _retryWrong(context),
                          icon: const Icon(Icons.replay_rounded, size: 19),
                          label: Text('Retry missed (${attempt.incorrect})'),
                        ),
                        const SizedBox(height: 10),
                      ],
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const QuizSetupScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('Build a new quiz'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const SectionHeader(
                    title: 'Review answers',
                    subtitle:
                        'Tap a question to see the correct answer, explanation, '
                        'and handout source.',
                  ),
                  const SizedBox(height: 12),
                  _ReviewList(
                    attempt: attempt,
                    termName: session.termName,
                    handoutTitle: session.handoutTitle,
                    showTutor: showTutor,
                  ),
                  const AttributionFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _retryWrong(BuildContext context) {
    final session = AppScope.of(context).session;
    final subject = session.packs.firstWhere(
      (pack) => pack.id == attempt.subjectId,
      orElse: () => session.subject,
    );
    final config = QuizService().retryWrongConfig(attempt);
    final result = QuizService().buildQuiz(
      pack: subject,
      config: config,
      history: session.attempts,
      bookmarks: session.bookmarks,
    );
    if (result.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The retry items are no longer available in the installed pack.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizScreen(buildResult: result, subject: subject),
      ),
    );
  }
}

class _ResultsHero extends StatelessWidget {
  const _ResultsHero({required this.attempt, required this.passed});

  final Attempt attempt;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    final statusColor = passed ? AppColors.green : AppColors.amber;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.navySoft, AppColors.blue],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          ScoreRing(
            value: attempt.score,
            size: 112,
            strokeWidth: 10,
            color: scoreColor(attempt.score),
            trackColor: Colors.white.withValues(alpha: 0.16),
            labelColor: Colors.white,
            labelSize: 24,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    passed ? 'PASSING RANGE' : 'KEEP REVIEWING',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${attempt.correct} of ${attempt.total} correct',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${dateLabel(attempt.finishedAt)} · '
                  '${durationLabel(attempt.duration)} · '
                  '${attempt.config.mode.label}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _DarkChip(
                      label: 'Weighted ${percentText(attempt.weightedScore)}',
                    ),
                    _DarkChip(
                      label: attempt.config.termIds.length > 1
                          ? 'Mixed terms'
                          : 'Single term',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkChip extends StatelessWidget {
  const _DarkChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TermBreakdown extends StatelessWidget {
  const _TermBreakdown({required this.termResults, required this.termName});

  final List<TermResult> termResults;
  final String Function(String) termName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < termResults.length; index++) ...[
            if (index > 0) const SizedBox(height: 14),
            LabeledProgress(
              label:
                  '${termName(termResults[index].termId)}  '
                  '(${termResults[index].correct}/'
                  '${termResults[index].total})',
              value: termResults[index].score,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  const _ReviewList({
    required this.attempt,
    required this.termName,
    required this.handoutTitle,
    required this.showTutor,
  });

  final Attempt attempt;
  final String Function(String) termName;
  final String Function(String) handoutTitle;
  final bool showTutor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < attempt.items.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            _ReviewItem(
              index: index,
              item: attempt.items[index],
              term: termName(attempt.items[index].termId),
              handout: handoutTitle(attempt.items[index].handoutId),
              showTutor: showTutor,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({
    required this.index,
    required this.item,
    required this.term,
    required this.handout,
    required this.showTutor,
  });

  final int index;
  final AttemptItem item;
  final String term;
  final String handout;
  final bool showTutor;

  @override
  Widget build(BuildContext context) {
    final accent = item.isCorrect
        ? AppColors.green
        : (item.selectedIndex == null ? AppColors.muted : AppColors.red);
    final yourAnswer = item.selectedIndex == null
        ? 'Not answered'
        : item.isModifiedTrueFalse
        ? item.options[item.selectedIndex!]
        : '${String.fromCharCode(65 + item.selectedIndex!)}. '
              '${item.options[item.selectedIndex!]}';
    final correctAnswer = item.isModifiedTrueFalse
        ? item.options[item.answerIndex]
        : '${String.fromCharCode(65 + item.answerIndex)}. '
              '${item.options[item.answerIndex]}';
    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      leading: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
      ),
      title: QuestionStem(
        text: item.stem,
        underlined: item.underlined,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${item.isModifiedTrueFalse ? 'Modified T/F · ' : ''}'
          '$term · Your answer: $yourAnswer',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            color: item.isCorrect ? AppColors.muted : accent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      children: [
        for (
          var optionIndex = 0;
          optionIndex < item.options.length;
          optionIndex++
        ) ...[
          _ReviewOption(
            letter: String.fromCharCode(65 + optionIndex),
            text: item.options[optionIndex],
            correct: optionIndex == item.answerIndex,
            selected: optionIndex == item.selectedIndex,
          ),
          if (optionIndex < item.options.length - 1) const SizedBox(height: 6),
        ],
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Correct answer',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.teal,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                correctAnswer,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                item.explanation,
                style: const TextStyle(fontSize: 12, height: 1.55),
              ),
              if (item.isModifiedTrueFalse &&
                  item.correction.trim().isNotEmpty) ...[
                const SizedBox(height: 9),
                Text(
                  'Correction: replace “${item.underlined}” with '
                  '“${item.correction}”.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '$handout · page ${item.sourcePage}',
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ],
          ),
        ),
        if (showTutor)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => showTutorSheet(
                context,
                stem: item.stem,
                options: item.options,
                answerIndex: item.answerIndex,
                explanation: item.explanation,
                topic: item.topic,
                handoutTitle: handout,
                sourcePage: item.sourcePage,
                difficulty: item.difficulty.name,
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: const Text('Ask tutor'),
            ),
          ),
      ],
    );
  }
}

class _ReviewOption extends StatelessWidget {
  const _ReviewOption({
    required this.letter,
    required this.text,
    required this.correct,
    required this.selected,
  });

  final String letter;
  final String text;
  final bool correct;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = correct
        ? AppColors.green
        : (selected ? AppColors.red : null);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color:
            accent?.withValues(alpha: 0.08) ??
            (isDark ? AppColors.darkBackground : AppColors.surfaceAlt),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              accent?.withValues(alpha: 0.5) ??
              (isDark ? AppColors.darkBorder : AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Text(
            letter,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: accent ?? AppColors.muted,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, height: 1.35),
            ),
          ),
          if (correct)
            const Icon(Icons.check_rounded, size: 15, color: AppColors.green),
          if (!correct && selected)
            const Icon(Icons.close_rounded, size: 15, color: AppColors.red),
        ],
      ),
    );
  }
}
