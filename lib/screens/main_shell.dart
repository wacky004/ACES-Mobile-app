import 'package:flutter/material.dart';

import '../features/ai/ai_feature.dart';
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

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Home',
          ),
          if (aiEnabled)
            const NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome_rounded),
              label: 'Tutor',
            ),
          const NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Progress',
          ),
          const NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books_rounded),
            label: 'Library',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
