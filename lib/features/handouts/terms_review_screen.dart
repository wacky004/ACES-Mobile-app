import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/reader_progress_controller.dart';
import '../../models/handout_reader.dart';
import '../../widgets/ui_kit.dart';

class ReaderTermEntry {
  const ReaderTermEntry({required this.handout, required this.term});
  final ReaderHandout handout;
  final ReaderTerm term;
}

class TermsReviewScreen extends StatefulWidget {
  const TermsReviewScreen({
    super.key,
    required this.title,
    required this.entries,
    required this.progress,
  });

  final String title;
  final List<ReaderTermEntry> entries;
  final ReaderProgressController progress;

  @override
  State<TermsReviewScreen> createState() => _TermsReviewScreenState();
}

class _TermsReviewScreenState extends State<TermsReviewScreen> {
  final _search = TextEditingController();
  late List<ReaderTermEntry> _entries;
  int _mode = 0;
  int _index = 0;
  bool _flipped = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _entries = List<ReaderTermEntry>.of(widget.entries);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ReaderTermEntry> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _entries;
    return _entries
        .where((entry) {
          return entry.term.term.toLowerCase().contains(query) ||
              entry.term.definition.toLowerCase().contains(query) ||
              entry.handout.title.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  void _next() {
    final entries = _filtered;
    if (entries.isEmpty) return;
    setState(() {
      _index = (_index + 1) % entries.length;
      _flipped = false;
    });
  }

  void _previous() {
    final entries = _filtered;
    if (entries.isEmpty) return;
    setState(() {
      _index = (_index - 1 + entries.length) % entries.length;
      _flipped = false;
    });
  }

  void _shuffle() {
    setState(() {
      _entries.shuffle();
      _index = 0;
      _flipped = false;
    });
  }

  Future<void> _setKnown(ReaderTermEntry entry, bool known) async {
    await widget.progress.setTermKnown(entry.term.id, known);
    if (!mounted) return;
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filtered;
    return ListenableBuilder(
      listenable: widget.progress,
      builder: (context, _) {
        final knownCount = _entries
            .where((entry) => widget.progress.isTermKnown(entry.term.id))
            .length;
        return Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Column(
                    children: [
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(
                            value: 0,
                            label: Text('Flashcards'),
                            icon: Icon(Icons.style_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: 1,
                            label: Text('List'),
                            icon: Icon(Icons.list_rounded, size: 16),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (value) =>
                            setState(() => _mode = value.first),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _search,
                        onChanged: (value) => setState(() {
                          _query = value;
                          _index = 0;
                          _flipped = false;
                        }),
                        decoration: InputDecoration(
                          hintText: 'Search terms or definitions…',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkSurface
                              : AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.darkBorder
                                  : AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.darkBorder
                                  : AppColors.border,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '$knownCount of ${_entries.length} known',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: _entries.isEmpty
                                    ? 0
                                    : knownCount / _entries.length,
                                minHeight: 5,
                                backgroundColor: AppColors.teal.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _mode == 0
                      ? _buildFlashcards(entries)
                      : _buildList(entries),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFlashcards(List<ReaderTermEntry> entries) {
    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No terms match',
        message: 'Try another search.',
      );
    }
    final safeIndex = _index.clamp(0, entries.length - 1);
    final entry = entries[safeIndex];
    final known = widget.progress.isTermKnown(entry.term.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => setState(() => _flipped = !_flipped),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: known
                        ? AppColors.green.withValues(alpha: 0.45)
                        : AppColors.teal.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _flipped ? 'Definition' : 'Term',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _flipped ? entry.term.definition : entry.term.term,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _flipped ? 16 : 24,
                        height: 1.45,
                        fontWeight: _flipped
                            ? FontWeight.w400
                            : FontWeight.w800,
                        letterSpacing: _flipped ? 0 : -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${entry.handout.number} · ${entry.handout.title} · '
                      'page ${entry.term.page}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                    if (known) ...[
                      const SizedBox(height: 10),
                      const StatusPill(
                        label: 'KNOWN',
                        color: AppColors.green,
                        icon: Icons.check_rounded,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _flipped
                          ? 'Tap to show the term'
                          : 'Tap to reveal the definition',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Previous',
                onPressed: _previous,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton.filledTonal(
                tooltip: 'Shuffle',
                onPressed: _shuffle,
                icon: const Icon(Icons.shuffle_rounded, size: 19),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => _setKnown(entry, false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text(
                  'Review again',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: () => _setKnown(entry, true),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Known', style: TextStyle(fontSize: 11)),
              ),
              const Spacer(),
              Text(
                '${safeIndex + 1}/${entries.length}',
                style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
              ),
              IconButton.filledTonal(
                tooltip: 'Next',
                onPressed: _next,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<ReaderTermEntry> entries) {
    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No terms match',
        message: 'Try another search.',
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        for (final entry in entries) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
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
                        entry.term.term,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: widget.progress.isTermKnown(entry.term.id)
                          ? 'Mark for review'
                          : 'Mark as known',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => widget.progress.setTermKnown(
                        entry.term.id,
                        !widget.progress.isTermKnown(entry.term.id),
                      ),
                      icon: Icon(
                        widget.progress.isTermKnown(entry.term.id)
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        color: widget.progress.isTermKnown(entry.term.id)
                            ? AppColors.green
                            : AppColors.muted,
                        size: 19,
                      ),
                    ),
                  ],
                ),
                Text(
                  entry.term.definition,
                  style: const TextStyle(fontSize: 11.5, height: 1.45),
                ),
                const SizedBox(height: 5),
                Text(
                  '${entry.handout.number} · page ${entry.term.page}',
                  style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
