import 'package:flutter/material.dart';

import '../../../models/imported_pdf.dart';
import '../../../state/app_scope.dart';
import '../ai_controller.dart';
import 'ai_widgets.dart';

class AiPdfChatScreen extends StatefulWidget {
  const AiPdfChatScreen({super.key, required this.pdf});

  final ImportedPdf pdf;

  @override
  State<AiPdfChatScreen> createState() => _AiPdfChatScreenState();
}

class _AiPdfChatScreenState extends State<AiPdfChatScreen> {
  AiController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final scope = AppScope.of(context);
    _controller = AiController(
      pdfRepository: scope.pdfRepository,
      chatRepository: scope.chatRepository,
      subjectId: scope.session.subject.id,
      chatContextKey: 'pdf:${widget.pdf.id}',
      pdfId: widget.pdf.id,
    );
    _controller!.initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pdf.filename,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: controller == null
          ? const Center(child: CircularProgressIndicator())
          : AiChatView(
              controller: controller,
              pdfId: widget.pdf.id,
              showSetupCard: true,
              showTermFilter: false,
              suggestions: const [
                'Summarize the key points',
                'What are the most important terms?',
                'Explain the main argument',
                'Give me 5 review pointers',
              ],
              emptyTitle: 'Chat with this PDF',
              emptyMessage:
                  'Relevant excerpts from this PDF are used automatically. '
                  'Local AI keeps them on this phone; cloud AI sends the '
                  'excerpts to the cloud. Scanned pages may contain OCR errors.',
            ),
    );
  }
}
