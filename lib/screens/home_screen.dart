import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/quiz_models.dart';
import '../state/app_scope.dart';
import '../state/app_session.dart';
import '../widgets/circuit_pattern.dart';
import '../widgets/logo.dart';
import '../widgets/score_ring.dart';
import '../widgets/ui_kit.dart';
import 'results_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onStartQuiz,
    required this.onReviewTerm,
    required this.onFocusWeakAreas,
  });

  final VoidCallback onStartQuiz;
  final ValueChanged<String> onReviewTerm;
  final VoidCallback onFocusWeakAreas;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final session = scope.session;
    final subject = session.subject;
    final weakTopics = session.weakTopics.take(3).toList();

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
                Row(
                  children: [
                    const LogoMark(size: 46),
                    const SizedBox(width: 12),
                    const Expanded(child: AppWordmark()),
                    if (session.packs.length > 1)
                      IconButton(
                        tooltip: 'Switch subject',
                        onPressed: () => _showSubjectSheet(context, session),
                        icon: const Icon(Icons.swap_horiz_rounded),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _HeroCard(
                  session: session,
                  onStartQuiz: onStartQuiz,
                  onCustomize: onStartQuiz,
                  onSwitchSubject: session.packs.length > 1
                      ? () => _showSubjectSheet(context, session)
                      : null,
                ),
                const SizedBox(height: 24),
                SectionHeader(
                  title: 'Review by term',
                  subtitle: subject.description.isEmpty
                      ? 'Pick a term to focus your practice.'
                      : subject.description,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 620 ? 4 : 2;
                    final spacing = 12.0;
                    final width =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                        columns;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final term in subject.terms)
                          SizedBox(
                            width: width,
                            child: _TermCard(
                              termName: term.name,
                              itemCount: subject.questionsForTerm(term.id),
                              mastery: session.termMastery(term.id),
                              onTap: () => onReviewTerm(term.id),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                if (weakTopics.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Weak areas',
                    subtitle: 'Topics with the lowest accuracy so far.',
                    actionLabel: 'Practice',
                    onAction: onFocusWeakAreas,
                  ),
                  const SizedBox(height: 12),
                  _WeakAreasCard(
                    topics: weakTopics,
                    session: session,
                    onPractice: onFocusWeakAreas,
                  ),
                ],
                if (session.attempts.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Recent attempts',
                    subtitle: 'Tap an attempt to review every answer.',
                  ),
                  const SizedBox(height: 12),
                  _RecentAttempts(session: session),
                ] else ...[
                  const SizedBox(height: 24),
                  EmptyState(
                    icon: Icons.quiz_outlined,
                    title: 'No attempts yet',
                    message:
                        'Take a 30-item quiz to start tracking mastery by term '
                        'and topic. Every answer includes an explanation.',
                    actionLabel: 'Start first quiz',
                    onAction: onStartQuiz,
                  ),
                ],
                const AttributionFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSubjectSheet(
    BuildContext context,
    AppSession session,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Subject library',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              for (final pack in session.packs)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const LogoMark(size: 38),
                  title: Text(
                    pack.subject,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${pack.code} · ${pack.questions.length} items',
                  ),
                  trailing: pack.id == session.subject.id
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.teal,
                        )
                      : null,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await session.selectSubject(pack.id);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.session,
    required this.onStartQuiz,
    required this.onCustomize,
    this.onSwitchSubject,
  });

  final AppSession session;
  final VoidCallback onStartQuiz;
  final VoidCallback onCustomize;
  final VoidCallback? onSwitchSubject;

  @override
  Widget build(BuildContext context) {
    final subject = session.subject;
    final mastery = session.weightedMastery;
    final weights = session.settings.weightsFor(subject);
    final weightTotal = weights.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CircuitPattern(color: Colors.white, opacity: 0.10),
            ),
            Positioned(
              right: -55,
              top: -45,
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/images/logo_mark.png',
                  width: 240,
                  height: 240,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _DarkPill(label: subject.code),
                      const SizedBox(width: 8),
                      const _DarkPill(label: 'OFFLINE'),
                      const Spacer(),
                      if (onSwitchSubject != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Switch subject',
                          onPressed: onSwitchSubject,
                          icon: const Icon(
                            Icons.unfold_more_rounded,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subject.subject,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1.22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (subject.org.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      subject.org,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      ScoreRing(
                        value: mastery,
                        size: 102,
                        strokeWidth: 9,
                        color: AppColors.tealBright,
                        trackColor: Colors.white.withValues(alpha: 0.16),
                        labelColor: Colors.white,
                        labelSize: 23,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Weighted mastery',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              weightTotal > 0
                                  ? '${session.answeredCount} answers recorded'
                                  : 'No answers recorded yet',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.62),
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _DarkStat(
                                  label: 'Accuracy',
                                  value: percentText(session.accuracy),
                                ),
                                _DarkStat(
                                  label: 'Attempts',
                                  value: '${session.attempts.length}',
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
                        flex: 3,
                        child: FilledButton.icon(
                          onPressed: onStartQuiz,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.navy,
                            minimumSize: const Size.fromHeight(48),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text(
                            'Start quiz',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed: onCustomize,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                          child: const Text(
                            'Customize',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkPill extends StatelessWidget {
  const _DarkPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _DarkStat extends StatelessWidget {
  const _DarkStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermCard extends StatelessWidget {
  const _TermCard({
    required this.termName,
    required this.itemCount,
    required this.mastery,
    required this.onTap,
  });

  final String termName;
  final int itemCount;
  final double mastery;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = mastery == 0 ? AppColors.muted : scoreColor(mastery);
    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      termName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.muted.withValues(alpha: 0.7),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '$itemCount items',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 13),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    percentText(mastery),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Text(
                      'mastery',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: mastery.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.22),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    mastery == 0
                        ? AppColors.muted.withValues(alpha: 0.4)
                        : accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeakAreasCard extends StatelessWidget {
  const _WeakAreasCard({
    required this.topics,
    required this.session,
    required this.onPractice,
  });

  final List<TopicStat> topics;
  final AppSession session;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < topics.length; index++) ...[
            if (index > 0) const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topics[index].topic,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${session.termName(topics[index].termId)} · '
                        '${topics[index].correct}/${topics[index].answered} correct',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusPill(
                  label: percentText(topics[index].accuracy),
                  color: scoreColor(topics[index].accuracy),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onPractice,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.teal,
              minimumSize: const Size.fromHeight(44),
              side: BorderSide(color: AppColors.teal.withValues(alpha: 0.4)),
            ),
            icon: const Icon(Icons.track_changes_rounded, size: 18),
            label: const Text('Practice weak areas'),
          ),
        ],
      ),
    );
  }
}

class _RecentAttempts extends StatelessWidget {
  const _RecentAttempts({required this.session});

  final AppSession session;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attempts = session.attempts.take(3).toList();
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
          for (var index = 0; index < attempts.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ResultsScreen(
                      attempt: attempts[index],
                      reviewOnly: true,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    ScoreRing(
                      value: attempts[index].score,
                      size: 42,
                      strokeWidth: 4.5,
                      label: percentText(attempts[index].score),
                      labelSize: 10.5,
                      animate: false,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attempts[index].config.termIds
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
                            '${dateLabel(attempts[index].finishedAt)} · '
                            '${attempts[index].correct}/${attempts[index].total} correct · '
                            '${attempts[index].config.mode.label}',
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
    );
  }
}
