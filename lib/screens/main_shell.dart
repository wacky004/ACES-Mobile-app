import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/layout.dart';
import '../core/theme.dart';
import '../features/ai/ai_feature.dart';
import '../features/updates/update_flow.dart';
import '../services/updates/update_service.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'progress_screen.dart';
import 'quiz_setup_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows && !kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoCheckUpdates());
    }
  }

  Future<void> _autoCheckUpdates() async {
    if (!mounted) return;
    if (!await UpdateService.instance.shouldAutoCheck()) return;
    if (!mounted) return;
    await checkForUpdates(context, silent: true);
  }

  void _openSetup({String? termId, bool focusWeakAreas = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizSetupScreen(
          initialTermId: termId,
          focusWeakAreas: focusWeakAreas,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiEnabled = AiFeature.supported;
    final pages = [
      HomeScreen(
        onStartQuiz: () => _openSetup(),
        onReviewTerm: (termId) => _openSetup(termId: termId),
        onFocusWeakAreas: () => _openSetup(focusWeakAreas: true),
      ),
      if (aiEnabled) AiFeature.buildTutorScreen(),
      ProgressScreen(
        onPracticeWeakAreas: () => _openSetup(focusWeakAreas: true),
      ),
      LibraryScreen(onSubjectOpened: () => setState(() => _index = 0)),
      const SettingsScreen(),
    ];
    final destinations = _destinations(aiEnabled);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= AppLayout.desktopBreakpoint;
        final content = IndexedStack(index: _index, children: pages);
        if (!useRail) {
          return Scaffold(
            body: content,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: destinations
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (value) =>
                    setState(() => _index = value),
                extended: constraints.maxWidth >= 1180,
                labelType: constraints.maxWidth >= 1180
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : AppColors.surface,
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
                  child: Icon(
                    Icons.school_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                destinations: destinations
                    .map(
                      (item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: Text(item.label),
                      ),
                    )
                    .toList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }

  List<_ShellDestination> _destinations(bool aiEnabled) => [
    const _ShellDestination(
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard_rounded,
      label: 'Home',
    ),
    if (aiEnabled)
      const _ShellDestination(
        icon: Icons.auto_awesome_outlined,
        selectedIcon: Icons.auto_awesome_rounded,
        label: 'Tutor',
      ),
    const _ShellDestination(
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
      label: 'Progress',
    ),
    const _ShellDestination(
      icon: Icons.library_books_outlined,
      selectedIcon: Icons.library_books_rounded,
      label: 'Library',
    ),
    const _ShellDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];
}

class _ShellDestination {
  const _ShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
