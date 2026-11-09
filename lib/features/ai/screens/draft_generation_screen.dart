import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/imported_pdf.dart';
import '../../../widgets/ui_kit.dart';
import '../ai_controller.dart';
import 'draft_review_screen.dart';

class DraftGenerationScreen extends StatefulWidget {
  const DraftGenerationScreen({
    super.key,
    required this.pdf,
    required this.controller,
    required this.count,
    this.useDeepSeek = false,
    this.useCompatible = false,
  });

  final ImportedPdf pdf;
  final AiController controller;
  final int count;
  final bool useDeepSeek;
  final bool useCompatible;

  @override
  State<DraftGenerationScreen> createState() => _DraftGenerationScreenState();
}

class _DraftGenerationScreenState extends State<DraftGenerationScreen> {
  bool _started = false;
  bool _cancelled = false;
  int _completed = 0;
  int _elapsedSeconds = 0;
  String _status = 'Preparing…';
  String? _error;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    setState(() {
      _error = null;
      _status = 'Generating questions…';
    });
    try {
      final draft = await widget.controller.generateDraft(
        widget.pdf,
        count: widget.count,
        useDeepSeek: widget.useDeepSeek,
        useCompatible: widget.useCompatible,
        onProgress: (completed, total, status) {
          if (!mounted) return;
          setState(() {
            _completed = completed;
            _status = status;
          });
        },
        isCancelled: () => _cancelled,
      );
      if (!mounted) return;
      if (_cancelled) {
        setState(() => _error = 'Generation cancelled.');
        return;
      }
      if (draft.questions.isEmpty) {
        setState(
          () => _error =
              'No valid questions were generated. Try a PDF with more text, '
              'or generate fewer questions.',
        );
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DraftReviewScreen(draft: draft)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    }
  }

  Future<void> _cancel() async {
    setState(() {
      _cancelled = true;
      _status = 'Cancelling…';
    });
    await widget.controller.cancelDraft();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.count;
    final progress = _completed == 0 || total == 0
        ? null
        : (_completed / total).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(title: const Text('Generating draft')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.teal,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Building a practice draft',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'From ${widget.pdf.filename} · target $total questions · '
                    '${widget.useCompatible
                        ? widget.controller.compatibleConfig.displayName
                        : widget.useDeepSeek
                        ? 'DeepSeek online'
                        : 'offline model'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_error == null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 9,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_completed of $total questions ready ? '
                      'elapsed ${_formatElapsed(_elapsedSeconds)}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.useCompatible
                            ? 'The handout excerpts for this PDF are sent to '
                                  '${widget.controller.compatibleConfig.displayName} '
                                  'to create the draft. Review every item before '
                                  'saving it to the library.'
                            : widget.useDeepSeek
                            ? 'The handout excerpts for this PDF are sent to '
                                  'DeepSeek to create the draft. Review every '
                                  'item before saving it to the library.'
                            : 'The first run can take one to three minutes '
                                  'while the phone loads the model. Keep the '
                                  'screen open and the device cool. You can '
                                  'cancel; completed items are kept as a draft.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10.5,
                          height: 1.4,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: _cancelled ? null : _cancel,
                      icon: const Icon(Icons.stop_rounded, size: 18),
                      label: Text(_cancelled ? 'Cancelling…' : 'Cancel'),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.45,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back'),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const AttributionFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatElapsed(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }
}
