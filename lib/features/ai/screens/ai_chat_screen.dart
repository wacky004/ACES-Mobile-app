import 'package:flutter/material.dart';

import '../../../state/app_scope.dart';
import '../ai_controller.dart';
import '../ai_models.dart';
import 'ai_widgets.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, this.question});

  final AiQuestionRequest? question;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  AiController? _controller;
  bool _asked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final scope = AppScope.of(context);
    _controller = AiController(
      pdfRepository: scope.pdfRepository,
      chatRepository: scope.chatRepository,
      subjectId: scope.session.subject.id,
    );
    _controller!.addListener(_maybeAsk);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _controller?.initialize();
    _maybeAsk();
  }

  void _maybeAsk() {
    final controller = _controller;
    final question = widget.question;
    if (controller == null || question == null || _asked) return;
    if (!controller.isReady || controller.isStreaming) return;
    _asked = true;
    controller.askAboutQuestion(
      question: question.question,
      options: question.options,
      answerIndex: question.answerIndex,
      explanation: question.explanation,
      topic: question.topic,
      handoutTitle: question.handoutTitle,
      sourcePage: question.sourcePage,
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_maybeAsk);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.question == null ? 'AI tutor' : 'Explain this item'),
      ),
      body: controller == null
          ? const Center(child: CircularProgressIndicator())
          : AiChatView(
              controller: controller,
              showSetupCard: true,
              suggestions: widget.question == null
                  ? const [
                      'Summarize this topic',
                      'Give me a memory hook',
                      'What are the key terms?',
                    ]
                  : const [],
              emptyTitle: widget.question == null
                  ? 'Ask your AI tutor'
                  : 'Preparing an explanation',
              emptyMessage: widget.question == null
                  ? 'Answers are grounded in the handouts and cite the page.'
                  : 'The model will explain this item using the handout context.',
            ),
    );
  }
}
