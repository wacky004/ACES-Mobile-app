import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'state/app_scope.dart';
import 'state/bootstrap.dart';
import 'widgets/logo.dart';

class CpeReviewerApp extends StatefulWidget {
  const CpeReviewerApp({super.key});

  @override
  State<CpeReviewerApp> createState() => _CpeReviewerAppState();
}

class _CpeReviewerAppState extends State<CpeReviewerApp> {
  late Future<Bootstrap> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = bootstrapApp();
  }

  void _retry() {
    setState(() {
      _bootstrapFuture = bootstrapApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Bootstrap>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            title: 'CPE Reviewer',
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(),
            home: _BootstrapErrorScreen(
              error: snapshot.error!,
              onRetry: _retry,
            ),
          );
        }
        final bootstrap = snapshot.data;
        if (bootstrap == null) {
          return MaterialApp(
            title: 'CPE Reviewer',
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(),
            home: const SplashScreen(),
          );
        }
        return AppScope(
          session: bootstrap.session,
          settings: bootstrap.settings,
          pdfRepository: bootstrap.pdfRepository,
          chatRepository: bootstrap.chatRepository,
          child: ListenableBuilder(
            listenable: bootstrap.settings,
            builder: (context, _) => MaterialApp(
              title: 'CPE Reviewer',
              debugShowCheckedModeBanner: false,
              theme: buildLightTheme(),
              darkTheme: buildDarkTheme(),
              themeMode: bootstrap.settings.themeMode,
              home: const MainShell(),
            ),
          ),
        );
      },
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  const _BootstrapErrorScreen({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const LogoMark(size: 96),
                const SizedBox(height: 22),
                const Text(
                  'Could not start the reviewer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The subject pack or local database could not be loaded. '
                  'Your progress is safe. Try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '$error',
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
