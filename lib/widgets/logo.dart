import 'package:flutter/material.dart';

import '../core/theme.dart';

class LogoMark extends StatelessWidget {
  const LogoMark({
    super.key,
    this.size = 56,
    this.plate = false,
    this.platePadding = 6,
  });

  final double size;
  final bool plate;
  final double platePadding;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/logo_mark.png',
      width: plate ? size - platePadding * 2 : size,
      height: plate ? size - platePadding * 2 : size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    if (!plate) return SizedBox(width: size, height: size, child: image);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(platePadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: image,
    );
  }
}

class LogoHero extends StatelessWidget {
  const LogoHero({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.06),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/logo_mark.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.compact = false, this.onDark = false});
  final bool compact;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = (onDark || isDark) ? Colors.white : AppColors.ink;
    final subColor = onDark
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.muted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'CPE Reviewer',
          style: TextStyle(
            fontSize: compact ? 16 : 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: color,
          ),
        ),
        if (!compact)
          Text(
            'Laws and Discipline · IT2205',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: subColor,
            ),
          ),
      ],
    );
  }
}
