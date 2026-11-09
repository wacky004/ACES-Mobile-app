import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../features/ai/ai_feature.dart';
import '../services/tutor_service.dart';
import '../state/app_scope.dart';
import '../state/app_session.dart';
import '../widgets/logo.dart';
import '../widgets/ui_kit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final session = scope.session;
    final settings = scope.settings;
    final subject = session.subject;
    final weights = settings.weightsFor(subject);
    final total = weights.values.fold<int>(0, (sum, value) => sum + value);

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
                  'Settings',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Tune the reviewer to match your class.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                _SettingsCard(
                  title: 'Grading weights',
                  subtitle:
                      'Used to split mixed quizzes and compute weighted mastery. '
                      'Values are normalized automatically.',
                  trailing: TextButton(
                    onPressed: () => settings.resetWeights(subject),
                    child: const Text('Reset'),
                  ),
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < subject.terms.length;
                        index++
                      ) ...[
                        if (index > 0) const Divider(height: 20),
                        _WeightRow(
                          label: subject.terms[index].name,
                          weight: weights[subject.terms[index].id] ?? 0,
                          percent: total == 0
                              ? 0
                              : (weights[subject.terms[index].id] ?? 0) / total,
                          onChanged: (value) => settings.setWeight(
                            subject,
                            subject.terms[index].id,
                            value,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          total == 0
                              ? 'All weights are zero. Mixed quizzes will split '
                                    'items evenly.'
                              : 'Current split: ${subject.terms.map((term) {
                                  final weight = weights[term.id] ?? 0;
                                  return '${term.name} '
                                      '${(weight / total * 100).round()}%';
                                }).join(' · ')}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            height: 1.4,
                            color: AppColors.teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SettingsCard(
                  title: 'Appearance',
                  subtitle: 'Match your phone or force a theme.',
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                      ),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (value) =>
                        settings.setThemeMode(value.first),
                    style: ButtonStyle(
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                if (TutorService.isSupported) ...[
                  const SizedBox(height: 14),
                  _SettingsCard(
                    title: 'Study tutor',
                    subtitle:
                        'Android only. Shows offline, handout-grounded '
                        'explanations for every answer.',
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: settings.tutorEnabled,
                      onChanged: settings.setTutorEnabled,
                      title: const Text(
                        'Enable tutor button',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: const Text(
                        'Appears in practice feedback and answer review.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
                if (AiFeature.supported) ...[
                  const SizedBox(height: 14),
                  AiFeature.buildSettingsCard(),
                ],
                const SizedBox(height: 14),
                _SettingsCard(
                  title: 'Data',
                  subtitle: 'Your study data stays on this device.',
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.restart_alt_rounded,
                          color: AppColors.red,
                        ),
                        title: const Text(
                          'Clear progress for this subject',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Deletes attempts and bookmarks. Questions stay.',
                          style: TextStyle(fontSize: 11),
                        ),
                        onTap: () => _confirmClearProgress(context, session),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.settings_backup_restore),
                        title: const Text(
                          'Reset all settings',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Restores default weights, theme, and tutor setting.',
                          style: TextStyle(fontSize: 11),
                        ),
                        onTap: () => _confirmResetSettings(context, session),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _AboutCard(session: session),
                const AttributionFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearProgress(
    BuildContext context,
    AppSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear progress?'),
        content: Text(
          'This deletes all attempts and bookmarks for '
          '${session.subject.subject}. This cannot be undone.',
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
      await session.clearProgress();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Progress cleared.')));
      }
    }
  }

  Future<void> _confirmResetSettings(
    BuildContext context,
    AppSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset settings?'),
        content: const Text(
          'Weights, theme, and tutor preferences return to their defaults. '
          'Attempts and bookmarks are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await session.settings.resetAll();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings reset.')));
      }
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _WeightRow extends StatelessWidget {
  const _WeightRow({
    required this.label,
    required this.weight,
    required this.percent,
    required this.onChanged,
  });

  final String label;
  final int weight;
  final double percent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${(percent * 100).round()}% of mixed quizzes',
                style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          onPressed: weight <= 0 ? null : () => onChanged(weight - 5),
          icon: const Icon(Icons.remove_rounded, size: 18),
        ),
        SizedBox(
          width: 42,
          child: Text(
            '$weight',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          onPressed: weight >= 100 ? null : () => onChanged(weight + 5),
          icon: const Icon(Icons.add_rounded, size: 18),
        ),
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.session});

  final AppSession session;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subject = session.subject;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          const LogoMark(size: 74),
          const SizedBox(height: 12),
          const Text(
            'CPE Reviewer',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Version 1.6.0',
            style: TextStyle(fontSize: 10.5, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 12),
          _AboutRow(label: 'Subject', value: subject.subject),
          _AboutRow(label: 'Course code', value: subject.code),
          _AboutRow(label: 'Pack version', value: subject.version),
          _AboutRow(label: 'Questions', value: '${subject.questions.length}'),
          _AboutRow(
            label: 'Publisher',
            value: subject.org.isEmpty ? 'ACES' : subject.org,
          ),
          if (subject.license.isNotEmpty)
            _AboutRow(label: 'License', value: subject.license),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.amber.withValues(alpha: 0.22),
              ),
            ),
            child: const Text(
              'Unofficial student reviewer. Handout content is property of '
              'STI. For classroom use only. Always verify answers against '
              'your official course materials.',
              style: TextStyle(
                fontSize: 10.5,
                height: 1.5,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
