import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/quiz_models.dart';
import '../models/subject_pack.dart';
import '../services/quiz_service.dart';
import '../state/app_scope.dart';
import '../state/app_session.dart';
import '../widgets/ui_kit.dart';
import 'quiz_screen.dart';

class QuizSetupScreen extends StatefulWidget {
  const QuizSetupScreen({
    super.key,
    this.initialTermId,
    this.focusWeakAreas = false,
  });

  final String? initialTermId;
  final bool focusWeakAreas;

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  final _service = QuizService();
  late AppSession _session;
  late Set<String> _selectedTerms;
  late int _itemCount;
  QuizMode _mode = QuizMode.practice;
  bool _focusWeak = false;
  bool _timer = false;
  Difficulty? _difficulty;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _session = AppScope.of(context).session;
    final subject = _session.subject;
    _selectedTerms = widget.initialTermId != null
        ? {widget.initialTermId!}
        : subject.terms.map((term) => term.id).toSet();
    _focusWeak = widget.focusWeakAreas;
    final available = _availableCount;
    _itemCount = min(30, available);
    if (_itemCount < 1) _itemCount = available;
  }

  SubjectPack get _subject => _session.subject;

  int get _availableCount {
    if (_selectedTerms.isEmpty) return 0;
    return _subject.questions
        .where(
          (question) =>
              _selectedTerms.contains(question.termId) &&
              (_difficulty == null || question.difficulty == _difficulty),
        )
        .length;
  }

  Map<String, int> get _weights =>
      AppScope.of(context).settings.weightsFor(_subject);

  int get _minItems {
    final available = _availableCount;
    if (available <= 0) return 0;
    return available >= 10 ? 10 : 1;
  }

  int get _maxItems {
    final available = _availableCount;
    return min(50, available);
  }

  void _clampItemCount() {
    final available = _availableCount;
    if (available <= 0) {
      _itemCount = 0;
      return;
    }
    final minValue = available >= 10 ? 10 : 1;
    final maxValue = min(50, available);
    _itemCount = _itemCount.clamp(minValue, maxValue);
  }

  void _toggleTerm(String termId, bool selected) {
    setState(() {
      if (selected) {
        _selectedTerms.add(termId);
      } else {
        _selectedTerms.remove(termId);
      }
      _clampItemCount();
    });
  }

  void _start() {
    if (_selectedTerms.isEmpty || _availableCount == 0) return;
    final config = QuizConfig(
      termIds: _selectedTerms.toList(),
      itemCount: _itemCount,
      weights: _weights,
      mode: _mode,
      focusWeakAreas: _focusWeak,
      timerEnabled: _timer,
      difficulty: _difficulty,
    );
    final result = _service.buildQuiz(
      pack: _subject,
      config: config,
      history: _session.attempts,
      bookmarks: _session.bookmarks,
    );
    if (result.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No questions match this setup. Try another filter.'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(buildResult: result, subject: _subject),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canStart = _selectedTerms.isNotEmpty && _availableCount > 0;
    final allocation = _service.allocate(
      count: _itemCount,
      termIds: _selectedTerms.toList(),
      weights: _weights,
    );
    final weights = _weights;
    final weightTotal = weights.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Build your quiz')),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.navy,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _subject.code,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subject.subject,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_subject.questions.length} total items · '
                          '${_subject.terms.length} terms',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.58),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SectionHeader(
                    title: 'Terms',
                    subtitle:
                        'Select one or mix several terms in the same quiz.',
                    actionLabel: _selectedTerms.length == _subject.terms.length
                        ? 'Clear'
                        : 'Select all',
                    onAction: () {
                      setState(() {
                        if (_selectedTerms.length == _subject.terms.length) {
                          _selectedTerms.clear();
                        } else {
                          _selectedTerms = _subject.terms
                              .map((term) => term.id)
                              .toSet();
                        }
                        _clampItemCount();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final term in _subject.terms)
                        FilterChip(
                          label: Text(
                            '${term.name} · ${_subject.questionsForTerm(term.id)}',
                          ),
                          selected: _selectedTerms.contains(term.id),
                          labelStyle: TextStyle(
                            color: _selectedTerms.contains(term.id)
                                ? Colors.white
                                : (isDark
                                      ? const Color(0xFFE8EEF8)
                                      : AppColors.ink),
                            fontWeight: FontWeight.w600,
                          ),
                          checkmarkColor: Colors.white,
                          onSelected: (selected) =>
                              _toggleTerm(term.id, selected),
                        ),
                    ],
                  ),
                  if (_selectedTerms.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Select at least one term to continue.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Number of items',
                    subtitle: _availableCount == 0
                        ? 'No items available for this selection.'
                        : '$_availableCount items available · max 50 per quiz',
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              '$_itemCount',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'items',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (_timer)
                              StatusPill(
                                label: '${_itemCount}m timer',
                                icon: Icons.timer_outlined,
                              ),
                          ],
                        ),
                        Slider(
                          value: _itemCount
                              .clamp(_minItems, max(_minItems, _maxItems))
                              .toDouble(),
                          min: _minItems.toDouble(),
                          max: max(_minItems, _maxItems).toDouble(),
                          divisions: _maxItems > _minItems
                              ? _maxItems - _minItems
                              : null,
                          label: '$_itemCount',
                          onChanged: canStart
                              ? (value) =>
                                    setState(() => _itemCount = value.round())
                              : null,
                        ),
                      ],
                    ),
                  ),
                  if (canStart && allocation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final term in _subject.terms)
                          if ((allocation[term.id] ?? 0) > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                '${term.name} ${allocation[term.id]}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.teal,
                                ),
                              ),
                            ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Allocation follows your grading weights '
                      '(${_subject.terms.map((term) {
                        final weight = weights[term.id] ?? 0;
                        final ratio = weightTotal == 0 ? 0 : weight / weightTotal;
                        return '${term.name} ${(ratio * 100).round()}%';
                      }).join(' · ')}). Change them in Settings.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Difficulty',
                    subtitle: 'Filter the pool before items are drawn.',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _difficulty == null,
                        onSelected: (_) {
                          setState(() {
                            _difficulty = null;
                            _clampItemCount();
                          });
                        },
                      ),
                      for (final difficulty in Difficulty.values)
                        ChoiceChip(
                          label: Text(difficulty.label),
                          selected: _difficulty == difficulty,
                          onSelected: (_) {
                            setState(() {
                              _difficulty = difficulty;
                              _clampItemCount();
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Mode',
                    subtitle:
                        'Practice reveals answers as you go. Exam reveals '
                        'everything after submission.',
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<QuizMode>(
                    segments: const [
                      ButtonSegment(
                        value: QuizMode.practice,
                        label: Text('Practice'),
                        icon: Icon(Icons.lightbulb_outline_rounded, size: 18),
                      ),
                      ButtonSegment(
                        value: QuizMode.exam,
                        label: Text('Exam'),
                        icon: Icon(Icons.assignment_outlined, size: 18),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (value) =>
                        setState(() => _mode = value.first),
                    style: ButtonStyle(
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: _focusWeak,
                          onChanged: (value) =>
                              setState(() => _focusWeak = value),
                          title: const Text(
                            'Focus weak areas',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: const Text(
                            'Prioritize topics with the lowest accuracy.',
                            style: TextStyle(fontSize: 11.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          value: _timer,
                          onChanged: (value) => setState(() => _timer = value),
                          title: const Text(
                            'Timed exam',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: const Text(
                            'One minute per item. Auto-submits at zero.',
                            style: TextStyle(fontSize: 11.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: canStart ? _start : null,
                    icon: const Icon(Icons.play_arrow_rounded, size: 21),
                    label: Text(
                      canStart
                          ? 'Start $_itemCount-item ${_mode.label.toLowerCase()}'
                          : 'Select terms to continue',
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Fresh items are prioritized. Questions and multiple-choice '
                      'options are shuffled every attempt; older items rotate '
                      'back when the fresh pool is exhausted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
