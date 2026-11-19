import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/ui_kit.dart';
import 'web_learning_resource.dart';
import 'web_learning_resources.dart';
import 'web_learning_screen.dart';

void openWebLearning(BuildContext context, WebLearningResource resource) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => WebLearningScreen(resource: resource)),
  );
}

class WebLearningHomeSection extends StatelessWidget {
  const WebLearningHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Web Learning',
          subtitle: 'Interactive labs by Dilum Sanjaya. Internet required.',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 820) {
              return SizedBox(
                height: 178,
                child: Row(
                  children: [
                    for (
                      var index = 0;
                      index < webLearningResources.length;
                      index++
                    ) ...[
                      if (index > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _WebLearningCard(
                          resource: webLearningResources[index],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }
            return SizedBox(
              height: 178,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: webLearningResources.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) => SizedBox(
                  width: 280,
                  child: _WebLearningCard(
                    resource: webLearningResources[index],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class WebLearningLibrarySection extends StatelessWidget {
  const WebLearningLibrarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Web Learning',
          subtitle:
              'Live interactive labs by Dilum Sanjaya. Internet required.',
        ),
        const SizedBox(height: 12),
        for (final resource in webLearningResources) ...[
          _WebLearningLibraryTile(resource: resource),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _WebLearningCard extends StatelessWidget {
  const _WebLearningCard({required this.resource});

  final WebLearningResource resource;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => openWebLearning(context, resource),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: resource.accent.withValues(alpha: isDark ? 0.35 : 0.25),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: resource.accent.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        resource.icon,
                        color: resource.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        resource.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const _OnlinePill(),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  resource.tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: resource.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    resource.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      height: 1.4,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        resource.lessonSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (resource.is3D)
                      const _TagPill(label: '3D')
                    else
                      const SizedBox.shrink(),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: resource.accent,
                      size: 17,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WebLearningLibraryTile extends StatelessWidget {
  const _WebLearningLibraryTile({required this.resource});

  final WebLearningResource resource;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 7, 10, 7),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: resource.accent.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(resource.icon, color: resource.accent, size: 21),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                resource.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const _OnlinePill(),
            if (resource.is3D) ...[
              const SizedBox(width: 4),
              const _TagPill(label: '3D'),
            ],
          ],
        ),
        subtitle: Text(
          '${resource.tagline} · ${resource.lessonSummary}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10.5, height: 1.4),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => openWebLearning(context, resource),
      ),
    );
  }
}

class _OnlinePill extends StatelessWidget {
  const _OnlinePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'ONLINE',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: AppColors.amber,
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: AppColors.teal,
        ),
      ),
    );
  }
}
