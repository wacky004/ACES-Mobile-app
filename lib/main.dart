import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_single_instance/windows_single_instance.dart';

import 'app.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await WindowsSingleInstance.ensureSingleInstance(
      args,
      'aces_cpe_reviewer',
      onSecondWindow: (_) {
        windowManager.show();
        windowManager.focus();
      },
    );
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1280, 860),
      minimumSize: Size(1024, 720),
      center: true,
      title: 'CPE Reviewer',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const CpeReviewerApp());
}
