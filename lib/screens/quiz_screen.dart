import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/quiz_models.dart';
import '../models/subject_pack.dart';
import '../services/quiz_service.dart';
import '../services/tutor_service.dart';
import '../state/app_scope.dart';
import '../widgets/question_stem.dart';
import '../widgets/tutor_sheet.dart';
import '../widgets/ui_kit.dart';
import 'results_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.buildResult,
    required this.subject,
  });

  final QuizBuildResult buildResult;
  final SubjectPack subject;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<QuizItem> _items;
  late final QuizConfig _config;
  late final DateTime _startedAt;
  final _service = QuizService();

  int _currentIndex = 0;
  Timer? _ticker;
  int _secondsLeft = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _items = widget.buildResult.items;
    _config = widget.buildResult.config;
    _startedAt = DateTime.now();
    if (_config.timerEnabled && _config.timeLimitSeconds != null) {
      _secondsLeft = _config.timeLimitSeconds!;
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _secondsLeft--;
        });
        if (_secondsLeft <= 0) {
          timer.cancel();
          _finish(auto: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  QuizItem get _current => _items[_currentIndex];
  int get _answeredCount =>
      _items.where((item) => item.selectedIndex != null).length;
  bool get _isPractice => _config.mode == QuizMode.practice;
  bool get _revealed => _isPractice && _current.isAnswered;
  bool get _isLast => _currentIndex == _items.length - 1;

  void _selectOption(int index) {
    if (_isPractice && _current.isAnswered) return;
    setState(() {
      _current.selectedIndex = index;
    });
  }

  void _next() {
    if (_isLast) {
      _confirmSubmit();
    } else {
      setState(() => _currentIndex++);
    }
  }

  void _previous() {
    if (_currentIndex == 0) return;
    setState(() => _currentIndex--);
  }

  Future<void> _confirmSubmit() async {
    if (_submitting) return;
    final unanswered = _items
        .where((item) => item.selectedIndex == null)
        .length;
    if (unanswered > 0) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('$unanswered unanswered'),
          content: const Text(
            'Unanswered items are counted as incorrect. Submit anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep answering'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      if (result != true) return;
    }
    _finish();
  }

  Future<void> _finish({bool auto = false}) async {
    if (_submitting) return;
    _submitting = true;
    _ticker?.cancel();
    final session = AppScope.of(context).session;
    final attempt = _service.createAttempt(
      subject: widget.subject,
      config: _config,
      items: _items,
      startedAt: _startedAt,
    );
    try {
      await session.recordAttempt(attempt);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save this attempt: $error')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(attempt: attempt, autoSubmitted: auto),
      ),
      (route) => route.isFirst,
    );
  }

  Future<void> _confirmExit() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this attempt?'),
        content: const Text(
          'Your answers for this attempt will not be saved to progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (shouldLeave == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleBookmark() async {
    final session = AppScope.of(context).session;
    await session.toggleBookmark(_current.question.id);
    if (!mounted) return;
    setState(() {
      _current.bookmarked = !_current.bookmarked;
    });
  }

  Future<void> _showPalette() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Question navigator',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap a number to jump. Flagged items show an amber dot.',
                style: TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var index = 0; index < _items.length; index++)
                        _PaletteTile(
                          number: index + 1,
                          answered: _items[index].selectedIndex != null,
                          flagged: _items[index].flagged,
                          current: index == _currentIndex,
                          onTap: () {
                            Navigator.pop(context);
                            setState(() => _currentIndex = index);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  _LegendDot(color: AppColors.teal, label: 'Answered'),
                  SizedBox(width: 14),
                  _LegendDot(color: AppColors.amber, label: 'Flagged'),
                  SizedBox(width: 14),
                  _LegendDot(color: AppColors.border, label: 'Unanswered'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTutor() async {
    final session = AppScope.of(context).session;
    final item = _current;
    await showTutorSheet(
      context,
      stem: item.question.stem,
      options: item.options,
      answerIndex: item.correctIndex,
      explanation: item.question.explanation,
      topic: item.question.topic,
      handoutTitle: session.handoutTitle(item.question.handoutId),
      sourcePage: item.question.sourcePage,
      difficulty: item.question.difficulty.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timerLow = _config.timerEnabled && _secondsLeft <= 60;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Exit attempt',
                    onPressed: _confirmExit,
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_config.mode.label} · Question ${_currentIndex + 1} of ${_items.length}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_answeredCount answered',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_config.timerEnabled)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (timerLow ? AppColors.red : AppColors.teal)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: timerLow ? AppColors.red : AppColors.teal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(_secondsLeft),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: timerLow ? AppColors.red : AppColors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  IconButton(
                    tooltip: 'Question navigator',
                    onPressed: _showPalette,
                    icon: const Icon(Icons.grid_view_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _items.length,
                  minHeight: 6,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Column(
                        key: ValueKey(_currentIndex),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              StatusPill(
                                label: _config.termIds.length == 1
                                    ? _termLabel
                                    : 'Mixed',
                                color: AppColors.blue,
                              ),
                              StatusPill(
                                label: _current.question.difficulty.label,
                                color: _difficultyColor,
                              ),
                              if (_current.question.isModifiedTrueFalse)
                                const StatusPill(
                                  label: 'MODIFIED T/F',
                                  color: AppColors.amber,
                                  icon: Icons.rule_rounded,
                                ),
                              if (_current.flagged)
                                const StatusPill(
                                  label: 'Flagged',
                                  color: AppColors.amber,
                                  icon: Icons.flag_rounded,
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          QuestionStem(
                            text: _current.question.stem,
                            underlined: _current.question.underlined,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.45,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (_current.question.isModifiedTrueFalse) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Choose True or False. If the statement is false, '
                              'the correction appears after you answer.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          if (_current.question.isModifiedTrueFalse)
                            Row(
                              children: [
                                for (
                                  var index = 0;
                                  index < _current.options.length;
                                  index++
                                ) ...[
                                  Expanded(
                                    child: _TrueFalseTile(
                                      text: _current.options[index],
                                      state: _optionState(index),
                                      onTap: () => _selectOption(index),
                                    ),
                                  ),
                                  if (index < _current.options.length - 1)
                                    const SizedBox(width: 10),
                                ],
                              ],
                            )
                          else
                            for (
                              var index = 0;
                              index < _current.options.length;
                              index++
                            ) ...[
                              _OptionTile(
                                letter: String.fromCharCode(65 + index),
                                text: _current.options[index],
                                state: _optionState(index),
                                onTap: () => _selectOption(index),
                              ),
                              if (index < _current.options.length - 1)
                                const SizedBox(height: 9),
                            ],
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            alignment: Alignment.topCenter,
                            child: _revealed
                                ? _FeedbackCard(
                                    item: _current,
                                    handoutTitle: AppScope.of(context).session
                                        .handoutTitle(
                                          _current.question.handoutId,
                                        ),
                                    showTutor:
                                        TutorService.isSupported &&
                                        AppScope.of(
                                          context,
                                        ).settings.tutorEnabled,
                                    onTutor: _showTutor,
                                  )
                                : const SizedBox(width: double.infinity),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: _current.bookmarked
                          ? 'Remove bookmark'
                          : 'Bookmark question',
                      onPressed: _toggleBookmark,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            (_current.bookmarked
                                    ? AppColors.teal
                                    : AppColors.muted)
                                .withValues(alpha: 0.12),
                        foregroundColor: _current.bookmarked
                            ? AppColors.teal
                            : AppColors.muted,
                      ),
                      icon: Icon(
                        _current.bookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      tooltip: _current.flagged
                          ? 'Remove flag'
                          : 'Flag question',
                      onPressed: () =>
                          setState(() => _current.flagged = !_current.flagged),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            (_current.flagged
                                    ? AppColors.amber
                                    : AppColors.muted)
                                .withValues(alpha: 0.12),
                        foregroundColor: _current.flagged
                            ? AppColors.amber
                            : AppColors.muted,
                      ),
                      icon: Icon(
                        _current.flagged
                            ? Icons.flag_rounded
                            : Icons.flag_outlined,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_currentIndex > 0)
                      OutlinedButton(
                        onPressed: _previous,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Prev'),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isLast ? _confirmSubmit : _next,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          backgroundColor: _isLast ? AppColors.teal : null,
                          foregroundColor: _isLast ? AppColors.navy : null,
                        ),
                        icon: Icon(
                          _isLast
                              ? Icons.check_circle_outline_rounded
                              : Icons.arrow_forward_rounded,
                          size: 19,
                        ),
                        label: Text(
                          _isLast
                              ? (_isPractice ? 'Finish' : 'Submit')
                              : 'Next',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _termLabel {
    final session = AppScope.of(context).session;
    return _config.termIds.isEmpty
        ? 'Mixed'
        : session.termName(_config.termIds.first);
  }

  Color get _difficultyColor => switch (_current.question.difficulty) {
    Difficulty.easy => AppColors.green,
    Difficulty.medium => AppColors.blue,
    Difficulty.hard => AppColors.amber,
  };

  _OptionState _optionState(int index) {
    if (!_revealed) {
      if (_current.selectedIndex == index) return _OptionState.selected;
      return _OptionState.idle;
    }
    if (index == _current.correctIndex) return _OptionState.correct;
    if (_current.selectedIndex == index && !_current.isCorrect) {
      return _OptionState.wrong;
    }
    return _OptionState.idle;
  }

  static String _formatTime(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = safe ~/ 60;
    final rest = safe % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }
}

enum _OptionState { idle, selected, correct, wrong }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    late Color border;
    late Color background;
    late Color letterBackground;
    late Color letterColor;
    IconData? trailing;

    switch (state) {
      case _OptionState.correct:
        border = AppColors.green;
        background = AppColors.green.withValues(alpha: 0.10);
        letterBackground = AppColors.green;
        letterColor = Colors.white;
        trailing = Icons.check_rounded;
      case _OptionState.wrong:
        border = AppColors.red;
        background = AppColors.red.withValues(alpha: 0.08);
        letterBackground = AppColors.red;
        letterColor = Colors.white;
        trailing = Icons.close_rounded;
      case _OptionState.selected:
        border = AppColors.teal;
        background = AppColors.teal.withValues(alpha: 0.08);
        letterBackground = AppColors.teal;
        letterColor = Colors.white;
      case _OptionState.idle:
        border = isDark ? AppColors.darkBorder : AppColors.border;
        background = isDark ? AppColors.darkSurface : AppColors.surface;
        letterBackground = isDark
            ? AppColors.darkBorder
            : AppColors.surfaceAlt;
        letterColor = AppColors.muted;
    }

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: border,
              width: state == _OptionState.idle ? 1 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: letterBackground,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: letterColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null)
                Icon(
                  trailing,
                  size: 19,
                  color: state == _OptionState.correct
                      ? AppColors.green
                      : AppColors.red,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrueFalseTile extends StatelessWidget {
  const _TrueFalseTile({
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTrue = text.toLowerCase() == 'true';
    late Color border;
    late Color background;
    late Color foreground;
    switch (state) {
      case _OptionState.correct:
        border = AppColors.green;
        background = AppColors.green.withValues(alpha: 0.10);
        foreground = AppColors.green;
      case _OptionState.wrong:
        border = AppColors.red;
        background = AppColors.red.withValues(alpha: 0.08);
        foreground = AppColors.red;
      case _OptionState.selected:
        border = AppColors.teal;
        background = AppColors.teal.withValues(alpha: 0.08);
        foreground = AppColors.teal;
      case _OptionState.idle:
        border = isDark ? AppColors.darkBorder : AppColors.border;
        background = isDark ? AppColors.darkSurface : AppColors.surface;
        foreground = AppColors.muted;
    }
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: border,
              width: state == _OptionState.idle ? 1 : 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                isTrue
                    ? Icons.check_circle_outline_rounded
                    : Icons.cancel_outlined,
                color: foreground,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                isTrue ? 'True' : 'False',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.item,
    required this.handoutTitle,
    required this.showTutor,
    required this.onTutor,
  });

  final QuizItem item;
  final String handoutTitle;
  final bool showTutor;
  final VoidCallback onTutor;

  @override
  Widget build(BuildContext context) {
    final correct = item.isCorrect;
    final accent = correct ? AppColors.green : AppColors.red;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: accent,
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                correct ? 'Correct' : 'Not quite',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
              const Spacer(),
              if (showTutor)
                TextButton.icon(
                  onPressed: onTutor,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.teal,
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                  label: const Text('Tutor', style: TextStyle(fontSize: 11.5)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.question.explanation,
            style: const TextStyle(fontSize: 12.8, height: 1.55),
          ),
          if (item.question.isModifiedTrueFalse &&
              item.question.correction.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Correction: replace ?${item.question.underlined}? with '
                '?${item.question.correction}?.',
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.45,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
          const SizedBox(height: 9),
          Text(
            '$handoutTitle · page ${item.question.sourcePage} · '
            '${item.question.topic}',
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.number,
    required this.answered,
    required this.flagged,
    required this.current,
    required this.onTap,
  });

  final int number;
  final bool answered;
  final bool flagged;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = current
        ? AppColors.navy
        : answered
        ? AppColors.teal.withValues(alpha: 0.14)
        : (isDark ? AppColors.darkSurface : AppColors.surface);
    final foreground = current
        ? Colors.white
        : answered
        ? AppColors.teal
        : AppColors.muted;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: current
                    ? AppColors.navy
                    : (isDark ? AppColors.darkBorder : AppColors.border),
              ),
            ),
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
          ),
        ),
        if (flagged)
          const Positioned(
            right: -2,
            top: -2,
            child: Icon(Icons.circle, size: 9, color: AppColors.amber),
          ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
        ),
      ],
    );
  }
}
