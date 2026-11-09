import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/handout_reader_repository.dart';
import '../../data/reader_progress_controller.dart';
import '../../models/handout_reader.dart';
import '../../models/quiz_models.dart';
import '../../services/quiz_service.dart';
import '../../services/reader_text_parts.dart';
import '../../state/app_scope.dart';
import '../../widgets/ui_kit.dart';
import 'reader_widgets.dart';
import 'terms_review_screen.dart';
import '../../screens/quiz_screen.dart';

class HandoutReaderScreen extends StatefulWidget {
  const HandoutReaderScreen({
    super.key,
    required this.handout,
    required this.pack,
    required this.progress,
  });

  final ReaderHandout handout;
  final HandoutReaderPack pack;
  final ReaderProgressController progress;

  @override
  State<HandoutReaderScreen> createState() => _HandoutReaderScreenState();
}

class _HandoutReaderScreenState extends State<HandoutReaderScreen> {
  late double _fontSize;
  int _segment = 0;
  late Future<List<ReaderTextPart>> _fullText;
  final _scrollController = ScrollController();
  int _textPartIndex = 0;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.progress.fontSize;
    _textPartIndex = widget.progress.textPartFor(
      widget.pack.subjectId,
      widget.handout.id,
    );
    _fullText = HandoutReaderRepository.instance
        .fullTextFor(widget.pack.subjectId, widget.handout.id)
        .then((pages) {
          final parts = buildReaderTextParts(pages);
          if (_textPartIndex >= parts.length) _textPartIndex = 0;
          return parts;
        });
    widget.progress.saveLast(widget.pack.subjectId, widget.handout.id, null);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String get _handoutTitle =>
      'Handout ${widget.handout.number}: ${widget.handout.title}';

  void _setFontSize(double size) {
    setState(() => _fontSize = size);
    widget.progress.setFontSize(size);
  }

  void _openTerms() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TermsReviewScreen(
          title: '${widget.handout.number} · Key terms',
          entries: [
            for (final term in widget.handout.terms)
              ReaderTermEntry(handout: widget.handout, term: term),
          ],
          progress: widget.progress,
        ),
      ),
    );
  }

  Future<void> _practice() async {
    final scope = AppScope.of(context);
    final session = scope.session;
    final questions = session.subject.questions
        .where((question) => question.handoutId == widget.handout.id)
        .toList(growable: false);
    if (questions.isEmpty) return;
    final config = QuizConfig(
      termIds: [widget.handout.termId],
      itemCount: questions.length,
      weights: scope.settings.weightsFor(session.subject),
      mode: QuizMode.practice,
      questionIds: questions.map((question) => question.id).toList(),
    );
    final result = QuizService().buildQuiz(
      pack: session.subject,
      config: config,
      history: session.attempts,
      bookmarks: session.bookmarks,
    );
    if (result.items.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            QuizScreen(buildResult: result, subject: session.subject),
      ),
    );
  }

  Future<void> _toggleRead() async {
    await widget.progress.markRead(
      widget.handout.id,
      !widget.progress.isRead(widget.handout.id),
    );
    if (mounted) setState(() {});
  }

  void _goToTextPart(List<ReaderTextPart> parts, int index) {
    if (index < 0 || index >= parts.length) return;
    setState(() => _textPartIndex = index);
    widget.progress.saveTextPart(
      widget.pack.subjectId,
      widget.handout.id,
      index,
    );
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _showPartPicker(List<ReaderTextPart> parts) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: parts.length,
            itemBuilder: (context, index) {
              final part = parts[index];
              final current = index == _textPartIndex;
              return ListTile(
                leading: Icon(
                  current ? Icons.check_circle_rounded : Icons.article_outlined,
                  color: current ? AppColors.teal : AppColors.muted,
                ),
                title: Text(
                  part.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  part.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _goToTextPart(parts, index);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    final termName = session.termName(widget.handout.termId);
    final read = widget.progress.isRead(widget.handout.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Handout ${widget.handout.number}'),
        actions: [
          PopupMenuButton<double>(
            tooltip: 'Text size',
            icon: const Icon(Icons.text_fields_rounded),
            initialValue: _fontSize,
            onSelected: _setFontSize,
            itemBuilder: (context) => [
              for (final size in const [14.0, 16.0, 18.0, 20.0, 22.0])
                PopupMenuItem(value: size, child: Text('${size.toInt()} pt')),
            ],
          ),
          IconButton(
            tooltip: read ? 'Mark as unread' : 'Mark as read',
            onPressed: _toggleRead,
            icon: Icon(
              read
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              color: read ? AppColors.green : null,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            StatusPill(label: termName, color: AppColors.blue),
                            const Spacer(),
                            StatusPill(
                              label: '${widget.handout.terms.length} terms',
                              color: AppColors.teal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.handout.title,
                          style: TextStyle(
                            fontSize: 19 * (_fontSize / 16).clamp(0.9, 1.18),
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.handout.summary,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: AppColors.muted,
                          ),
                        ),
                        if (widget.handout.terms.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final term in widget.handout.terms)
                                ActionChip(
                                  label: Text(term.term),
                                  onPressed: () => showTermSheet(
                                    context,
                                    term: term,
                                    handoutTitle: _handoutTitle,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openTerms,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(42),
                                  foregroundColor: AppColors.teal,
                                  side: BorderSide(
                                    color: AppColors.teal.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.style_rounded, size: 17),
                                label: const Text('Terms'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _practice,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(42),
                                  backgroundColor: AppColors.navy,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.quiz_outlined, size: 17),
                                label: const Text('Practice'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('Review'),
                        icon: Icon(Icons.notes_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('Full text'),
                        icon: Icon(Icons.article_outlined, size: 16),
                      ),
                    ],
                    selected: {_segment},
                    onSelectionChanged: (value) =>
                        setState(() => _segment = value.first),
                  ),
                  const SizedBox(height: 16),
                  if (_segment == 0)
                    _ReviewContent(handout: widget.handout, fontSize: _fontSize)
                  else
                    FutureBuilder<List<ReaderTextPart>>(
                      future: _fullText,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final parts = snapshot.data ?? const [];
                        if (parts.isEmpty) {
                          return const EmptyState(
                            icon: Icons.description_outlined,
                            title: 'Full text unavailable',
                            message:
                                'The source text for this handout could not be loaded.',
                          );
                        }
                        if (_textPartIndex >= parts.length) {
                          _textPartIndex = parts.length - 1;
                        }
                        final part = parts[_textPartIndex];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reading in parts ? ${_textPartIndex + 1} of '
                              '${parts.length} ? ${part.label}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                height: 1.4,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: (_textPartIndex + 1) / parts.length,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.border,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.article_outlined,
                                        size: 15,
                                        color: AppColors.teal,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          part.label,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.teal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 9),
                                  SelectableText(
                                    part.text,
                                    style: TextStyle(
                                      fontSize: _fontSize - 2,
                                      height: 1.65,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _textPartIndex == 0
                                        ? null
                                        : () => _goToTextPart(
                                            parts,
                                            _textPartIndex - 1,
                                          ),
                                    icon: const Icon(
                                      Icons.arrow_back_rounded,
                                      size: 17,
                                    ),
                                    label: const Text('Previous'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.outlined(
                                  tooltip: 'Jump to a part',
                                  onPressed: () => _showPartPicker(parts),
                                  icon: const Icon(Icons.list_rounded),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed:
                                        _textPartIndex >= parts.length - 1
                                        ? null
                                        : () => _goToTextPart(
                                            parts,
                                            _textPartIndex + 1,
                                          ),
                                    icon: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 17,
                                    ),
                                    label: const Text('Next'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 10),
                  const AttributionFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewContent extends StatelessWidget {
  const _ReviewContent({required this.handout, required this.fontSize});

  final ReaderHandout handout;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scale = (fontSize / 16).clamp(0.9, 1.25);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < handout.sections.length; index++) ...[
          if (index > 0) const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  handout.sections[index].title,
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ),
              StatusPill(
                label: 'p. ${handout.sections[index].page}',
                color: AppColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final bullet in handout.sections[index].bullets)
            Padding(
              padding: EdgeInsets.only(left: 4, bottom: 7 * scale),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 6 * scale),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      bullet,
                      style: TextStyle(
                        fontSize: fontSize * 0.82,
                        height: 1.55,
                        color: isDark ? const Color(0xFFDDE6F4) : AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          for (final table in handout.tablesFor(handout.sections[index]))
            ReaderTableView(table: table, fontScale: scale),
        ],
      ],
    );
  }
}
