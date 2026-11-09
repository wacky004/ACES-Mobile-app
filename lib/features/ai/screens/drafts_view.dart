import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/imported_pdf.dart';
import '../../../widgets/ui_kit.dart';
import '../ai_controller.dart';
import 'draft_review_screen.dart';

class DraftsView extends StatelessWidget {
  const DraftsView({super.key, required this.controller});

  final AiController controller;

  Future<void> _delete(BuildContext context, DraftSet draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this draft?'),
        content: Text(
          'Remove ${draft.questions.length} generated questions from '
          '${draft.filename}? The saved subject pack, if any, is not removed.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteDraft(draft.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final drafts = controller.drafts;
        if (drafts.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: const [
              EmptyState(
                icon: Icons.quiz_outlined,
                title: 'No AI drafts yet',
                message:
                    'Open a PDF, tap "Draft quiz", and the offline model will '
                    'create a short draft for you to review.',
              ),
            ],
          );
        }
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const SectionHeader(
              title: 'AI drafts',
              subtitle:
                  'Unverified generated items. Review and edit before using.',
            ),
            const SizedBox(height: 10),
            for (final draft in drafts) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.quiz_outlined,
                        color: AppColors.amber,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            draft.filename,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${draft.questions.length} questions · '
                            '${dateLabel(draft.createdAt)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const StatusPill(
                            label: 'AI DRAFT · UNVERIFIED',
                            color: AppColors.amber,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete draft',
                      onPressed: () => _delete(context, draft),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 19,
                        color: AppColors.red,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Review',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DraftReviewScreen(draft: draft),
                        ),
                      ),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
            ],
          ],
        );
      },
    );
  }
}
