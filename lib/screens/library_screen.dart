import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/pack_repository.dart';
import '../features/handouts/handouts_home_view.dart';
import '../models/subject_pack.dart';
import '../state/app_scope.dart';
import '../state/app_session.dart';
import '../widgets/logo.dart';
import '../widgets/ui_kit.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.onSubjectOpened});

  final VoidCallback onSubjectOpened;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _importing = false;
  int _segment = 0;

  Future<void> _importPack() async {
    if (_importing) return;
    setState(() => _importing = true);
    final session = AppScope.of(context).session;
    try {
      final picked = await FilePicker.pickFile(
        dialogTitle: 'Select a subject pack (.json)',
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final pack = await session.packRepository.importBytes(bytes);
      await session.reloadPacks();
      if (!mounted) return;
      await _showInstalled(session, pack);
    } on PackValidationException catch (error) {
      if (mounted) _showError(error.problems.join('\n'));
    } on FormatException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError('$error');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _showInstalled(AppSession session, SubjectPack pack) async {
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pack installed'),
        content: Text(
          '${pack.subject}\n'
          '${pack.questions.length} items · version ${pack.version}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: const Text('Open now'),
          ),
        ],
      ),
    );
    if (open == true) {
      await session.selectSubject(pack.id);
      widget.onSubjectOpened();
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import failed'),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(fontSize: 12.5, height: 1.5),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final session = scope.session;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final packs = session.packs;

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
                  'Library',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Read the handouts or switch subject packs. Everything works offline.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('Handouts'),
                      icon: Icon(Icons.menu_book_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Subjects'),
                      icon: Icon(Icons.library_books_rounded, size: 16),
                    ),
                  ],
                  selected: {_segment},
                  onSelectionChanged: (value) =>
                      setState(() => _segment = value.first),
                ),
                const SizedBox(height: 18),
                if (_segment == 0) const HandoutsHomeView(),
                if (_segment == 1) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.navy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.upload_file_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Import a subject pack',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'JSON file · new subjects or additional exam items',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _importing ? null : _importPack,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.navy,
                            minimumSize: const Size(0, 42),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: _importing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.navy,
                                  ),
                                )
                              : const Text('Import'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Installed subjects',
                    subtitle:
                        '${packs.length} pack${packs.length == 1 ? '' : 's'} on this device',
                  ),
                  const SizedBox(height: 12),
                  for (final pack in packs) ...[
                    _SubjectCard(
                      pack: pack,
                      current: pack.id == session.subject.id,
                      onOpen: () async {
                        await session.selectSubject(pack.id);
                        widget.onSubjectOpened();
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 10),
                  _PackFormatCard(),
                  const SizedBox(height: 12),
                  const AttributionFooter(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.pack,
    required this.current,
    required this.onOpen,
  });

  final SubjectPack pack;
  final bool current;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: current
              ? AppColors.teal.withValues(alpha: 0.55)
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: current ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LogoMark(size: 50, plate: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pack.subject,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (current)
                          const StatusPill(
                            label: 'CURRENT',
                            color: AppColors.teal,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${pack.code} · ${pack.org}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pack.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              pack.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: AppColors.muted,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusPill(
                label: '${pack.questions.length} items',
                color: AppColors.blue,
                icon: Icons.quiz_outlined,
              ),
              StatusPill(
                label: '${pack.terms.length} terms',
                color: AppColors.teal,
                icon: Icons.date_range_outlined,
              ),
              StatusPill(
                label: 'v${pack.version}',
                color: AppColors.muted,
                icon: Icons.sell_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: current ? null : onOpen,
              icon: Icon(
                current ? Icons.check_rounded : Icons.menu_book_rounded,
                size: 18,
              ),
              label: Text(current ? 'Currently open' : 'Open subject'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackFormatCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
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
          const Row(
            children: [
              Icon(Icons.handyman_outlined, size: 18, color: AppColors.teal),
              SizedBox(width: 7),
              Text(
                'For partner orgs',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'A subject pack can define its own terms and default weights, so '
            'other courses and orgs can join without an app update. Each pack '
            'carries its org, authors, version, and license for attribution.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: const Text(
              'Full pack: id, subject, code, org, version, terms[] '
              '(id, name, order, defaultWeight), handouts[], questions[]\n\n'
              'Question: id, termId, handoutId, topic, difficulty, type, '
              'stem, options, answerIndex, explanation, sourcePage. MCQs use '
              '4 options; modifiedTrueFalse uses True/False plus underlined '
              'and correction.\n\n'
              'Merge file: subjectId, version, questions[]',
              style: TextStyle(
                fontSize: 10,
                height: 1.5,
                fontFamily: 'monospace',
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
