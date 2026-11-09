import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';
import '../state/app_scope.dart';
import '../widgets/score_ring.dart';
import '../widgets/ui_kit.dart';
import 'quiz_screen.dart';
import 'results_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, required this.onPracticeWeakAreas});

  final VoidCallback onPracticeWeakAreas;

  void _reviewBookmarks(BuildContext context) {
    final session = AppScope.of(context).session;
    final ids = session.bookmarks.toList();
    if (ids.isEmpty) return;
    final subject = session.subject;
    final config = QuizConfig(
      termIds: const [],
      itemCount: ids.length,
      weights: session.settings.weightsFor(subject),
      mode: QuizMode.practice,
      questionIds: ids,
    );
    final result = QuizService().buildQuiz(
      pack: subject,
      config: config,
      history: session.attempts,
      bookmarks: session.bookmarks,
    );
    if (result.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Those bookmarked questions are no longer available.'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(buildResult: result, subject: subject),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weakTopics = session.weakTopics.take(6).toList();

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your progress',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${session.subject.code} · ${session.subject.subject}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ScoreRing(
                            value: session.weightedMastery,
                            size: 110,
                            strokeWidth: 10,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Weighted mastery',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Progress rolls up by term using your '
                                  'configured weights.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.4,
                                    color: AppColors.muted.withValues(
                                      alpha: 0.95,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    StatusPill(
                                      label:
                                          '${session.attempts.length} attempt${session.attempts.length == 1 ? '' : 's'}',
                                      color: AppColors.blue,
                                    ),
                                    const SizedBox(width: 6),
                                    StatusPill(
                                      label:
                                          '${session.answeredCount} answered',
                                      color: AppColors.teal,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: MetricTile(
                              label: 'Accuracy',
                              value: percentText(session.accuracy),
                              icon: Icons.my_location_rounded,
                              accent: AppColors.teal,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MetricTile(
                              label: 'Correct',
                              value: '${session.correctCount}',
                              icon: Icons.check_circle_outline_rounded,
                              accent: AppColors.green,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MetricTile(
                              label: 'Items',
                              value: '${session.totalQuestions}',
                              icon: Icons.menu_book_rounded,
                              accent: AppColors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Mastery by term',
                  subtitle: 'Accuracy across every recorded answer.',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < session.subject.terms.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(height: 15),
                        Builder(
                          builder: (context) {
                            final term = session.subject.terms[index];
                            final stat = session.termStat(term.id);
                            return LabeledProgress(
                              label: term.name,
                              value: stat.accuracy,
                              trailing: stat.answered == 0
                                  ? 'No data'
                                  : '${stat.correct}/${stat.answered} · '
                                        '${percentText(stat.accuracy)}',
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeader(
                  title: 'Weak topics',
                  subtitle:
                      'Lowest accuracy first. Use this list to target '
                      'your next review session.',
                  actionLabel: weakTopics.isNotEmpty ? 'Practice' : null,
                  onAction: weakTopics.isNotEmpty ? onPracticeWeakAreas : null,
                ),
                const SizedBox(height: 12),
                if (weakTopics.isEmpty)
                  const EmptyState(
                    icon: Icons.track_changes_rounded,
                    title: 'No weak-topic data yet',
                    message:
                        'Complete a quiz and the app will rank topics by '
                        'accuracy so you know exactly what to review next.',
                  )
                else
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < weakTopics.length;
                          index++
                        ) ...[
                          if (index > 0) const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        weakTopics[index].topic,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${session.termName(weakTopics[index].termId)} · '
                                        '${weakTopics[index].correct}/'
                                        '${weakTopics[index].answered} correct',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusPill(
                                  label: percentText(
                                    weakTopics[index].accuracy,
                                  ),
                                  color: scoreColor(weakTopics[index].accuracy),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        OutlinedButton.icon(
                          onPressed: onPracticeWeakAreas,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.teal,
                            minimumSize: const Size.fromHeight(44),
                            side: BorderSide(
                              color: AppColors.teal.withValues(alpha: 0.4),
                            ),
                          ),
                          icon: const Icon(
                            Icons.track_changes_rounded,
                            size: 18,
                          ),
                          label: const Text('Practice weak areas'),
                        ),
                      ],
                    ),
                  ),
                if (session.bookmarks.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Bookmarks',
                    subtitle: 'Questions you saved for later.',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.bookmark_rounded,
                            color: AppColors.teal,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${session.bookmarks.length} saved '
                                'question${session.bookmarks.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Practice only what you bookmarked.',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _reviewBookmarks(context),
                          child: const Text('Review'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Attempt history',
                  subtitle: 'Tap an attempt to review its answers.',
                ),
                const SizedBox(height: 12),
                if (session.attempts.isEmpty)
                  const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No attempts recorded',
                    message:
                        'Your attempts appear here once you submit a quiz.',
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < session.attempts.length;
                          index++
                        ) ...[
                          if (index > 0)
                            const Divider(height: 1, indent: 16, endIndent: 16),
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ResultsScreen(
                                    attempt: session.attempts[index],
                                    reviewOnly: true,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  ScoreRing(
                                    value: session.attempts[index].score,
                                    size: 44,
                                    strokeWidth: 4.5,
                                    label: percentText(
                                      session.attempts[index].score,
                                    ),
                                    labelSize: 10.5,
                                    animate: false,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          session.attempts[index].config.termIds
                                              .map(session.termName)
                                              .join(' + '),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${dateLabel(session.attempts[index].finishedAt)} · '
                                          '${session.attempts[index].correct}/'
                                          '${session.attempts[index].total} correct · '
                                          '${session.attempts[index].config.mode.label}',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const AttributionFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
