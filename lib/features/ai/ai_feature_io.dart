import 'package:flutter/material.dart';

import 'ai_models.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/ai_settings_card.dart';
import 'screens/ai_tutor_screen.dart';

class AiFeature {
  static bool get supported => true;

  static Widget buildTutorScreen() => const AiTutorScreen();

  static Widget buildSettingsCard() => const AiSettingsCard();

  static Future<void> askAboutQuestion(
    BuildContext context, {
    required String question,
    required List<String> options,
    required int answerIndex,
    required String explanation,
    required String topic,
    required String handoutTitle,
    required int sourcePage,
  }) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => AiChatScreen(
          question: AiQuestionRequest(
            question: question,
            options: options,
            answerIndex: answerIndex,
            explanation: explanation,
            topic: topic,
            handoutTitle: handoutTitle,
            sourcePage: sourcePage,
          ),
        ),
      ),
    );
  }
}
