import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/imported_pdf.dart';
import '../../../models/subject_pack.dart';
import '../../../state/app_scope.dart';
import '../../../widgets/ui_kit.dart';
import '../../../screens/quiz_setup_screen.dart';

class DraftReviewScreen extends StatefulWidget {
  const DraftReviewScreen({super.key, required this.draft});

  final DraftSet draft;

  @override
  State<DraftReviewScreen> createState() => _DraftReviewScreenState();
}

class _DraftReviewScreenState extends State<DraftReviewScreen> {
  late List<DraftQuestion> _questions;
  bool _reviewed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _questions = List<DraftQuestion>.of(widget.draft.questions);
  }

  Future<void> _edit(int index) async {
    final updated = await showDialog<DraftQuestion>(
      context: context,
      builder: (_) => _EditDraftQuestionDialog(question: _questions[index]),
    );
    if (updated == null || !mounted) return;
    setState(() => _questions[index] = updated);
  }

  Future<void> _saveAndPractice() async {
    if (_questions.isEmpty || _saving) return;
    setState(() => _saving = true);
    final scope = AppScope.of(context);
    final session = scope.session;
    final packId = 'draft-${widget.draft.id}';
    const handoutId = 'pdf-source';
    final pack = SubjectPack(
      id: packId,
      subject: 'PDF Draft · ${widget.draft.filename}',
      code: 'PDF',
      org: 'AI (unverified)',
      version: '1.0.0',
      description:
          'AI-generated draft from ${widget.draft.filename}. Review every item before use.',
      authors: const ['AI'],
      license: 'AI draft — unverified. Handout content belongs to its owner.',
      terms: const [
        Term(id: 'pdf', name: 'PDF Draft', order: 1, defaultWeight: 100),
      ],
      handouts: [
        Handout(
          id: handoutId,
          termId: 'pdf',
          number: 'PDF',
          title: widget.draft.filename,
        ),
      ],
      questions: [
        for (var index = 0; index < _questions.length; index++)
          Question(
            id: '$packId-q${index + 1}',
            termId: 'pdf',
            handoutId: handoutId,
            topic: _questions[index].topic,
            difficulty: Difficulty.parse(_questions[index].difficulty),
            stem: _questions[index].stem,
            options: _questions[index].options,
            answerIndex: _questions[index].answerIndex,
            explanation: _questions[index].explanation,
            sourcePage: _questions[index].sourcePage,
          ),
      ],
    );

    final problems = SubjectPack.validate(pack);
    if (problems.isNotEmpty) {
      if (!mounted) return;
      setState(() => _saving = false);
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Fix these items first'),
          content: Text(problems.take(6).join('\n')),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      await session.packRepository.save(pack);
      await session.reloadPacks();
      await session.selectSubject(pack.id);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const QuizSetupScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save the pack: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review AI draft')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_outlined,
                    color: AppColors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'AI-generated draft from ${widget.draft.filename}. '
                      'Edit or delete anything that is wrong, then confirm you '
                      'reviewed all ${_questions.length} items.',
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.45,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_questions.isEmpty)
              const EmptyState(
                icon: Icons.quiz_outlined,
                title: 'No draft items',
                message:
                    'The AI did not produce a usable item. Try generating fewer '
                    'questions or importing a PDF with more text.',
              )
            else
              for (var index = 0; index < _questions.length; index++) ...[
                _DraftCard(
                  index: index,
                  question: _questions[index],
                  onEdit: () => _edit(index),
                  onDelete: () {
                    setState(() => _questions.removeAt(index));
                  },
                ),
                const SizedBox(height: 10),
              ],
            if (_questions.isNotEmpty) ...[
              const SizedBox(height: 6),
              CheckboxListTile(
                value: _reviewed,
                onChanged: (value) =>
                    setState(() => _reviewed = value ?? false),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'I reviewed every item and corrected mistakes.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Saving creates a new subject in your library.',
                  style: TextStyle(fontSize: 10.5),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _reviewed && !_saving ? _saveAndPractice : null,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.library_add_rounded, size: 19),
                label: Text(_saving ? 'Saving…' : 'Save to library & practice'),
              ),
              const SizedBox(height: 8),
              const Text(
                'The draft stays in your PDF library so you can review it again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ],
            const AttributionFooter(),
          ],
        ),
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.index,
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final DraftQuestion question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
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
              Container(
                width: 27,
                height: 27,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    StatusPill(label: question.topic, color: AppColors.teal),
                    StatusPill(
                      label: question.difficulty,
                      color: AppColors.blue,
                    ),
                    StatusPill(
                      label: 'page ${question.sourcePage}',
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              IconButton(
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.stem,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          for (
            var optionIndex = 0;
            optionIndex < question.options.length;
            optionIndex++
          )
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: optionIndex == question.answerIndex
                    ? AppColors.green.withValues(alpha: 0.09)
                    : (isDark
                          ? AppColors.darkBackground
                          : AppColors.surfaceAlt),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: optionIndex == question.answerIndex
                      ? AppColors.green.withValues(alpha: 0.4)
                      : (isDark ? AppColors.darkBorder : AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    String.fromCharCode(65 + optionIndex),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: optionIndex == question.answerIndex
                          ? AppColors.green
                          : AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.options[optionIndex],
                      style: const TextStyle(fontSize: 11, height: 1.35),
                    ),
                  ),
                  if (optionIndex == question.answerIndex)
                    const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.green,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            question.explanation,
            style: const TextStyle(
              fontSize: 11,
              height: 1.45,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditDraftQuestionDialog extends StatefulWidget {
  const _EditDraftQuestionDialog({required this.question});

  final DraftQuestion question;

  @override
  State<_EditDraftQuestionDialog> createState() =>
      _EditDraftQuestionDialogState();
}

class _EditDraftQuestionDialogState extends State<_EditDraftQuestionDialog> {
  late final TextEditingController _stem;
  late final List<TextEditingController> _options;
  late final TextEditingController _explanation;
  late final TextEditingController _topic;
  late int _answerIndex;
  late String _difficulty;

  @override
  void initState() {
    super.initState();
    _stem = TextEditingController(text: widget.question.stem);
    _options = [
      for (final option in widget.question.options)
        TextEditingController(text: option),
    ];
    _explanation = TextEditingController(text: widget.question.explanation);
    _topic = TextEditingController(text: widget.question.topic);
    _answerIndex = widget.question.answerIndex.clamp(0, 3);
    _difficulty = widget.question.difficulty;
  }

  @override
  void dispose() {
    _stem.dispose();
    for (final controller in _options) {
      controller.dispose();
    }
    _explanation.dispose();
    _topic.dispose();
    super.dispose();
  }

  void _save() {
    final stem = _stem.text.trim();
    final options = _options
        .map((controller) => controller.text.trim())
        .toList();
    final explanation = _explanation.text.trim();
    if (stem.isEmpty ||
        explanation.isEmpty ||
        options.any((option) => option.isEmpty) ||
        options.toSet().length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fill the stem, four unique options, and explanation.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      DraftQuestion(
        id: widget.question.id,
        sourcePage: widget.question.sourcePage,
        topic: _topic.text.trim().isEmpty ? 'PDF' : _topic.text.trim(),
        difficulty: _difficulty,
        stem: stem,
        options: options,
        answerIndex: _answerIndex,
        explanation: explanation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit draft item'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _stem,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Question stem',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              for (var index = 0; index < 4; index++) ...[
                TextField(
                  controller: _options[index],
                  decoration: InputDecoration(
                    labelText: 'Option ${String.fromCharCode(65 + index)}',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 7),
              ],
              DropdownButtonFormField<int>(
                initialValue: _answerIndex,
                decoration: const InputDecoration(
                  labelText: 'Correct option',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (var index = 0; index < 4; index++)
                    DropdownMenuItem(
                      value: index,
                      child: Text('Option ${String.fromCharCode(65 + index)}'),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _answerIndex = value ?? _answerIndex),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _explanation,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Explanation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _topic,
                      decoration: const InputDecoration(
                        labelText: 'Topic',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _difficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'easy', child: Text('Easy')),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(value: 'hard', child: Text('Hard')),
                      ],
                      onChanged: (value) =>
                          setState(() => _difficulty = value ?? _difficulty),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          child: const Text('Save item'),
        ),
      ],
    );
  }
}
