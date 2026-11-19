import 'package:flutter/material.dart';

class AppLayout {
  const AppLayout._();

  static const double desktopBreakpoint = 900;
  static const double mobileContentWidth = 720;
  static const double desktopContentWidth = 1120;
  static const double readerWidth = 920;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  static double contentWidth(BuildContext context) =>
      isDesktop(context) ? desktopContentWidth : mobileContentWidth;
}
