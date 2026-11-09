import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/circuit_pattern.dart';
import '../widgets/logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CircuitPattern(color: AppColors.navy, opacity: 0.08),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      const LogoMark(size: 168),
                      const SizedBox(height: 26),
                      const Text(
                        'CPE Reviewer',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.9,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Computer Engineering Reviewer',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 34),
                      const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.blue,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'ACES - Association of Computer Engineering Students',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy.withValues(alpha: 0.68),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'STI Ortigas-Cainta',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.navy.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
