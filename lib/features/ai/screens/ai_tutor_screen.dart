import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../state/app_scope.dart';
import '../ai_controller.dart';
import 'ai_widgets.dart';
import 'drafts_view.dart';
import 'pdf_library_view.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  AiController? _controller;
  String? _subjectId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    final subjectId = scope.session.subject.id;
    if (_controller == null) {
      _subjectId = subjectId;
      _controller = AiController(
        pdfRepository: scope.pdfRepository,
        chatRepository: scope.chatRepository,
        subjectId: subjectId,
        chatContextKey: 'tutor:$subjectId',
      );
      _controller!.initialize();
      return;
    }
    if (_subjectId != subjectId) {
      _subjectId = subjectId;
      _controller!.switchSubject(subjectId, chatContextKey: 'tutor:$subjectId');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final showSetup = !controller.isReady || controller.downloading;
        return SafeArea(
          bottom: false,
          child: DefaultTabController(
            length: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.teal,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI tutor',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              controller.usesCompatible
                                  ? (controller.compatibleReady
                                        ? '${controller.compatibleConfig.displayName} · online custom provider'
                                        : 'Custom cloud selected · setup needed')
                                  : controller.usesDeepSeek
                                  ? (controller.deepSeekReady
                                        ? 'DeepSeek online · ${controller.deepSeekModel.displayName}'
                                        : 'DeepSeek selected · add an API key')
                                  : controller.localAiEnabled
                                  ? 'Runs on this phone · English only · cites the handouts'
                                  : 'Local AI is off · turn it on in AI settings',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (showSetup)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: AiModelCard(controller: controller),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: TabBar(
                    labelColor: AppColors.teal,
                    unselectedLabelColor: AppColors.muted,
                    indicatorColor: AppColors.teal,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                    tabs: const [
                      Tab(text: 'Chat'),
                      Tab(text: 'PDFs'),
                      Tab(text: 'Drafts'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      AiChatView(
                        controller: controller,
                        showTermFilter: false,
                        suggestions: const [
                          'Explain the key terms in this handout',
                          'Quiz me on this subject',
                          'Give me a memory hook',
                          'Summarize the main ideas',
                        ],
                      ),
                      PdfLibraryView(controller: controller),
                      DraftsView(controller: controller),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
