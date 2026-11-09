import 'package:flutter/widgets.dart';

class AiFeature {
  static bool get supported => false;

  static Widget buildTutorScreen() => const SizedBox.shrink();

  static Widget buildSettingsCard() => const SizedBox.shrink();

  static Future<void> askAboutQuestion(
    BuildContext context, {
    required String question,
    required List<String> options,
    required int answerIndex,
    required String explanation,
    required String topic,
    required String handoutTitle,
    required int sourcePage,
  }) async {}
}
