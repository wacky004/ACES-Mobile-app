import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/imported_pdf.dart';
import '../../../widgets/ui_kit.dart';
import '../ai_controller.dart';
import 'ai_pdf_chat_screen.dart';
import 'draft_generation_screen.dart';

class PdfLibraryView extends StatefulWidget {
  const PdfLibraryView({super.key, required this.controller});

  final AiController controller;

  @override
  State<PdfLibraryView> createState() => _PdfLibraryViewState();
}

class _PdfLibraryViewState extends State<PdfLibraryView> {
  bool _importing = false;
  int _progress = 0;
  String _status = '';
  bool _cancelRequested = false;

  Future<void> _importPdf() async {
    if (_importing) return;
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Choose a PDF handout',
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (picked == null) return;
    setState(() {
      _importing = true;
      _cancelRequested = false;
      _progress = 0;
      _status = 'Reading the file…';
    });
    try {
      final bytes = await picked.readAsBytes();
      final pdf = await widget.controller.importPdf(
        bytes,
        picked.name,
        onProgress: (progress, status) {
          if (!mounted) return;
          setState(() {
            _progress = progress;
            _status = status;
          });
        },
        isCancelled: () => _cancelRequested,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${pdf.pages} pages · ${pdf.chunks.length} searchable chunks',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() {
          _importing = false;
          _progress = 0;
          _status = '';
        });
      }
    }
  }

  Future<void> _startDraft(ImportedPdf pdf) async {
    if (!widget.controller.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Connect a cloud provider or download an offline AI model first.',
          ),
        ),
      );
      return;
    }
    final count = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Generate draft questions'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Text(
              'The AI will create unverified practice items from this PDF. '
              'Review every item before saving it to the library.',
              style: TextStyle(fontSize: 11.5, height: 1.4),
            ),
          ),
          for (final value in [5, 10, 15])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, value),
              child: Row(
                children: [
                  Icon(
                    value == 10
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: value == 10 ? AppColors.teal : AppColors.muted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$value questions',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (value == 10) ...[
                    const SizedBox(width: 6),
                    const Text(
                      'recommended',
                      style: TextStyle(fontSize: 10, color: AppColors.teal),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
    if (count == null || !mounted) return;
    final localReady = widget.controller.selectedModelInstalled;
    final options = <String>[
      if (localReady) 'local',
      if (widget.controller.deepSeekReady) 'deepseek',
      if (widget.controller.compatibleReady) 'compatible',
    ];
    String? provider;
    if (options.length == 1) {
      provider = options.first;
    } else {
      provider = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Generate with'),
          children: [
            if (localReady)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'local'),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.memory_rounded, color: AppColors.teal),
                  title: Text('Offline model'),
                  subtitle: Text(
                    'Private: the excerpt stays on this phone.',
                    style: TextStyle(fontSize: 10.5),
                  ),
                ),
              ),
            if (widget.controller.deepSeekReady)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'deepseek'),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.cloud_queue_rounded,
                    color: AppColors.blue,
                  ),
                  title: Text('DeepSeek online'),
                  subtitle: Text(
                    'Sends handout excerpts to DeepSeek.',
                    style: TextStyle(fontSize: 10.5),
                  ),
                ),
              ),
            if (widget.controller.compatibleReady)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'compatible'),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.hub_outlined,
                    color: AppColors.blue,
                  ),
                  title: Text(widget.controller.compatibleConfig.displayName),
                  subtitle: const Text(
                    'Sends handout excerpts to your custom cloud provider.',
                    style: TextStyle(fontSize: 10.5),
                  ),
                ),
              ),
          ],
        ),
      );
      if (provider == null || !mounted) return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DraftGenerationScreen(
          pdf: pdf,
          controller: widget.controller,
          count: count,
          useDeepSeek: provider == 'deepseek',
          useCompatible: provider == 'compatible',
        ),
      ),
    );
  }

  Future<void> _deletePdf(ImportedPdf pdf) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this PDF?'),
        content: Text(
          '${pdf.filename} and its draft sets will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.controller.deletePdf(pdf.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PDF removed.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final pdfs = widget.controller.pdfs;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.teal,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Study your own PDFs',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Text PDFs are extracted; scanned pages use offline OCR. '
                          'Imported files are stored on this phone.',
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.35,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _importing ? null : _importPdf,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text('Import PDF'),
                  ),
                ],
              ),
            ),
            if (_importing) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkSurface
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBorder
                        : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _status,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '$_progress%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress / 100,
                        minHeight: 7,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            setState(() => _cancelRequested = true),
                        child: const Text(
                          'Cancel after this page',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            SectionHeader(
              title: 'My PDFs',
              subtitle: pdfs.isEmpty
                  ? 'No PDFs imported yet.'
                  : '${pdfs.length} PDF${pdfs.length == 1 ? '' : 's'} on this device.',
            ),
            const SizedBox(height: 10),
            if (pdfs.isEmpty)
              EmptyState(
                icon: Icons.picture_as_pdf_outlined,
                title: 'No PDFs yet',
                message:
                    'Import a handout or reading, chat with it using your '
                    'selected AI, or generate a short draft quiz for review.',
                actionLabel: _importing ? null : 'Import a PDF',
                onAction: _importing ? null : _importPdf,
              )
            else
              for (final pdf in pdfs) ...[
                _PdfCard(
                  pdf: pdf,
                  modelReady: widget.controller.isReady,
                  onChat: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AiPdfChatScreen(pdf: pdf),
                    ),
                  ),
                  onDraft: () => _startDraft(pdf),
                  onDelete: () => _deletePdf(pdf),
                ),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 8),
            const Text(
              'AI draft quizzes are unverified. Review and edit every item '
              'before using them for practice or class review.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                height: 1.4,
                color: AppColors.muted,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PdfCard extends StatelessWidget {
  const _PdfCard({
    required this.pdf,
    required this.modelReady,
    required this.onChat,
    required this.onDraft,
    required this.onDelete,
  });

  final ImportedPdf pdf;
  final bool modelReady;
  final VoidCallback onChat;
  final VoidCallback onDraft;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdf.filename,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${pdf.pages} pages · ${pdf.chunks.length} chunks · '
                      '${dateLabel(pdf.createdAt)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (pdf.ocrUsed)
                const StatusPill(
                  label: 'OCR',
                  color: AppColors.amber,
                  icon: Icons.document_scanner_outlined,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              OutlinedButton.icon(
                onPressed: onChat,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  foregroundColor: AppColors.teal,
                  side: BorderSide(
                    color: AppColors.teal.withValues(alpha: 0.35),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                label: const Text('Chat', style: TextStyle(fontSize: 11.5)),
              ),
              OutlinedButton.icon(
                onPressed: modelReady ? onDraft : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.quiz_outlined, size: 15),
                label: const Text(
                  'Draft quiz',
                  style: TextStyle(fontSize: 11.5),
                ),
              ),
              IconButton(
                tooltip: 'Remove PDF',
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
          if (!modelReady)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                'Draft generation needs DeepSeek or an offline model.',
                style: TextStyle(fontSize: 9.5, color: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}
