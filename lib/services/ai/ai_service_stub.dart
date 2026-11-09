import 'package:flutter/foundation.dart';

/// Web-only placeholder. The AI feature is never compiled into the web app,
/// but this file keeps the interface analyzable on non-io analysis passes.
class AiService {
  static bool get isSupported => false;
  static AiService get instance => AiService();
  static final ValueNotifier<int> modelRevision = ValueNotifier<int>(0);

  Future<void> initialize() async {}

  Future<bool> isInstalled(dynamic spec) async => false;

  Future<void> ensureActive(dynamic spec) async {}

  Future<void> loadModel(dynamic spec) async {}

  Future<void> unloadModel() async {}

  Stream<String> ask({
    dynamic spec,
    required String systemPrompt,
    required String userPrompt,
    int maxOutputTokens = 500,
  }) =>
      Stream<String>.error(
        UnsupportedError('Offline AI is not available on this platform.'),
      );

  Future<void> stop() async {}

  Future<void> deleteModel(dynamic spec) async {}
}
