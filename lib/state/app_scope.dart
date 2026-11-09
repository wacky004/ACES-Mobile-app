import 'package:flutter/widgets.dart';

import '../data/chat_repository.dart';
import '../data/pdf_repository.dart';
import '../data/settings_controller.dart';
import 'app_session.dart';

class AppScope extends InheritedNotifier<Listenable> {
  AppScope({
    super.key,
    required this.session,
    required this.settings,
    required this.pdfRepository,
    required this.chatRepository,
    required super.child,
  }) : super(notifier: Listenable.merge([session, settings]));

  final AppSession session;
  final SettingsController settings;
  final PdfRepository pdfRepository;
  final ChatRepository chatRepository;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget.');
    return scope!;
  }
}
