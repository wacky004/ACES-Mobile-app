import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/handout_reader_repository.dart';
import '../../data/reader_progress_controller.dart';
import '../../models/handout_reader.dart';
import '../../state/app_scope.dart';
import '../../widgets/ui_kit.dart';
import 'handout_reader_screen.dart';
import 'terms_review_screen.dart';

class HandoutsHomeView extends StatefulWidget {
  const HandoutsHomeView({super.key});

  @override
  State<HandoutsHomeView> createState() => _HandoutsHomeViewState();
}

class _HandoutsHomeViewState extends State<HandoutsHomeView> {
  final _progress = ReaderProgressController();
  final _search = TextEditingController();
  HandoutReaderPack? _pack;
  String? _error;
  bool _loading = true;
  String _query = '';
  String? _termFilter;
  String? _loadedSubjectId;

  @override
  void initState() {
    super.initState();
    _progress.load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final subjectId = AppScope.of(context).session.subject.id;
    if (_loadedSubjectId == subjectId) return;
    _loadedSubjectId = subjectId;
    _pack = null;
    _error = null;
    _loading = true;
    _termFilter = null;
    _loadPack(subjectId);
  }

  @override
  void dispose() {
    _search.dispose();
    _progress.dispose();
    super.dispose();
  }

  Future<void> _loadPack(String subjectId) async {
    try {
      final pack = await HandoutReaderRepository.instance.loadPackFor(
        subjectId,
      );
      if (!mounted || _loadedSubjectId != subjectId) return;
      setState(() {
        _pack = pack;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || _loadedSubjectId != subjectId) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  void _openReader(ReaderHandout handout, HandoutReaderPack pack) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HandoutReaderScreen(
          handout: handout,
          pack: pack,
          progress: _progress,
        ),
      ),
    );
  }

  void _openTerms(HandoutReaderPack pack) {
    final entries = [
      for (final handout in pack.handouts)
        for (final term in handout.terms)
          ReaderTermEntry(handout: handout, term: term),
    ];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TermsReviewScreen(
          title: 'All handout terms',
          entries: entries,
          progress: _progress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final session = scope.session;
    final pack = _pack;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'Reader could not load',
          message: _error!,
        ),
      );
    }
    if (pack == null || pack.handouts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'No reader content',
          message: 'This subject does not include a handout reader yet.',
        ),
      );
    }
    final terms = session.subject.terms;
    final selectedTerms = _termFilter == null
        ? pack.handouts.map((handout) => handout.termId).toSet()
        : {_termFilter!};
    final visibleHandouts = pack.handouts
        .where((handout) => selectedTerms.contains(handout.termId))
        .toList(growable: false);
    final searchHits = _query.trim().isEmpty
        ? const <ReaderSearchHit>[]
        : HandoutReaderRepository.instance.search(pack, _query);
    final lastId = _progress.lastHandoutFor(session.subject.id);
    final last = lastId == null ? null : pack.handoutById(lastId);

    return ListenableBuilder(
      listenable: _progress,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search handouts, terms, or tables…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBorder
                        : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBorder
                        : AppColors.border,
                  ),
                ),
              ),
            ),
            if (_query.trim().isEmpty) ...[
              if (last != null) ...[
                const SizedBox(height: 14),
                _ContinueCard(
                  handout: last,
                  onTap: () => _openReader(last, pack),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Handouts',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openTerms(pack),
                    icon: const Icon(Icons.style_rounded, size: 16),
                    label: const Text(
                      'All terms',
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _termFilter == null,
                    onSelected: (_) => setState(() => _termFilter = null),
                  ),
                  for (final term in terms)
                    ChoiceChip(
                      label: Text(term.name),
                      selected: _termFilter == term.id,
                      onSelected: (_) => setState(() => _termFilter = term.id),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              for (final term in terms)
                if (selectedTerms.contains(term.id)) ...[
                  if (pack.handoutsForTerm(term.id).isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 7),
                      child: Text(
                        term.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    for (final handout in pack.handoutsForTerm(term.id))
                      _HandoutCard(
                        handout: handout,
                        termName: term.name,
                        read: _progress.isRead(handout.id),
                        quizCount: session.subject.questions
                            .where(
                              (question) => question.handoutId == handout.id,
                            )
                            .length,
                        onTap: () => _openReader(handout, pack),
                      ),
                    const SizedBox(height: 8),
                  ],
                ],
              if (visibleHandouts.isEmpty)
                const EmptyState(
                  icon: Icons.filter_alt_off_rounded,
                  title: 'No handouts for this filter',
                  message: 'Choose another term to continue.',
                ),
            ] else ...[
              const SizedBox(height: 14),
              if (searchHits.isEmpty)
                EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matches',
                  message:
                      'Try a term, law number, or a topic such as '
                      '"wiretapping" or "data privacy".',
                )
              else
                for (final hit in searchHits)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      switch (hit.kind) {
                        ReaderSearchKind.term => Icons.style_rounded,
                        ReaderSearchKind.table => Icons.table_chart_outlined,
                        ReaderSearchKind.section => Icons.subject_rounded,
                        ReaderSearchKind.handout => Icons.menu_book_rounded,
                      },
                      color: AppColors.teal,
                      size: 20,
                    ),
                    title: Text(
                      hit.title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${hit.handout.number} · ${hit.snippet}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, height: 1.35),
                    ),
                    onTap: () => _openReader(hit.handout, pack),
                  ),
            ],
            const SizedBox(height: 18),
            const AttributionFooter(),
          ],
        );
      },
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.handout, required this.onTap});

  final ReaderHandout handout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.teal.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.teal,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Continue reading',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${handout.number} · ${handout.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.teal),
            ],
          ),
        ),
      ),
    );
  }
}

class _HandoutCard extends StatelessWidget {
  const _HandoutCard({
    required this.handout,
    required this.termName,
    required this.read,
    required this.quizCount,
    required this.onTap,
  });

  final ReaderHandout handout;
  final String termName;
  final bool read;
  final int quizCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    handout.number,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: read ? AppColors.green : AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      handout.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (read)
                    const StatusPill(
                      label: 'READ',
                      color: AppColors.green,
                      icon: Icons.check_rounded,
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                handout.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  height: 1.4,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  StatusPill(label: termName, color: AppColors.blue),
                  StatusPill(
                    label: '${handout.sections.length} sections',
                    color: AppColors.muted,
                  ),
                  StatusPill(
                    label: '${handout.terms.length} terms',
                    color: AppColors.teal,
                  ),
                  if (handout.tables.isNotEmpty)
                    StatusPill(
                      label: '${handout.tables.length} tables',
                      color: AppColors.amber,
                    ),
                  if (quizCount > 0)
                    StatusPill(
                      label: '$quizCount items',
                      color: AppColors.blue,
                      icon: Icons.quiz_outlined,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
