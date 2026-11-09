import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../features/ai/ai_feature.dart';
import '../services/tutor_service.dart';

Future<void> showTutorSheet(
  BuildContext context, {
  required String stem,
  required List<String> options,
  required int answerIndex,
  required String explanation,
  required String topic,
  required String handoutTitle,
  required int sourcePage,
  required String difficulty,
}) async {
  final answer = await TutorService.explain(
    subjectTitle: 'CPE Reviewer',
    stem: stem,
    options: options,
    answerIndex: answerIndex,
    explanation: explanation,
    topic: topic,
    handoutTitle: handoutTitle,
    sourcePage: sourcePage,
    difficulty: difficulty,
  );
  if (!context.mounted) return;
  final pageContext = context;
  await showModalBottomSheet<void>(
    context: pageContext,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.teal,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Study tutor',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                answer.body,
                style: const TextStyle(fontSize: 13.5, height: 1.55),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              answer.source,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            if (AiFeature.supported) ...[
              const SizedBox(height: 2),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  AiFeature.askAboutQuestion(
                    pageContext,
                    question: stem,
                    options: options,
                    answerIndex: answerIndex,
                    explanation: explanation,
                    topic: topic,
                    handoutTitle: handoutTitle,
                    sourcePage: sourcePage,
                  );
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: AppColors.teal.withValues(alpha: 0.12),
                  foregroundColor: AppColors.teal,
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Ask the tutor'),
              ),
            ],
            const SizedBox(height: 10),
            const Text(
              'The quick answer above runs on this phone.',
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.muted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
