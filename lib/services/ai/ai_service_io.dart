import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_llama/flutter_edge_ai_llama.dart';

import 'ai_config.dart';
import 'ai_model_catalog.dart';
import 'model_store.dart';

class AiService {
  AiService._();

  static final AiService _instance = AiService._();
  static bool get isSupported => true;
  static AiService get instance => _instance;
  static final ValueNotifier<int> modelRevision = ValueNotifier<int>(0);

  final ModelStore store = ModelStore();

  bool _initialized = false;
  Future<void>? _initFuture;
  InferenceModel? _model;
  InferenceChat? _activeChat;
  AiModelSpec? _activeSpec;
  Future<void>? _loadingFuture;

  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    _initFuture ??= _initializeInternal();
    return _initFuture!;
  }

  Future<void> _initializeInternal() async {
    await FlutterEdgeAi.initialize(
      inferenceEngines: const [LlamaEngineProvider()],
    );
    _initialized = true;
  }

  Future<bool> isInstalled(AiModelSpec spec) => store.isDownloaded(spec);

  Future<void> ensureActive(AiModelSpec spec) async {
    await initialize();
    if (_activeSpec?.id == spec.id) return;
    await _closeLoadedModel();
    final file = await store.fileFor(spec);
    if (!await file.exists() || await file.length() != spec.sizeBytes) {
      throw StateError(
        '${spec.displayName} is not installed. Download it from Models.',
      );
    }
    await FlutterEdgeAi.installModel(
      modelType: spec.modelType,
      fileType: ModelFileType.gguf,
    ).fromFile(file.path).install();
    _activeSpec = spec;
  }

  Future<void> loadModel(AiModelSpec spec) async {
    if (_model != null && _activeSpec?.id == spec.id) return;
    _loadingFuture ??= _loadModelInternal(spec);
    try {
      await _loadingFuture;
    } finally {
      _loadingFuture = null;
    }
  }

  Future<void> _loadModelInternal(AiModelSpec spec) async {
    await ensureActive(spec);
    _model = await FlutterEdgeAi.getActiveModel(
      maxTokens: aiContextTokens,
    );
  }

  Future<void> _closeLoadedModel() async {
    final chat = _activeChat;
    _activeChat = null;
    if (chat != null) {
      try {
        await chat.close();
      } catch (_) {}
    }
    final model = _model;
    _model = null;
    if (model != null) {
      try {
        await model.close();
      } catch (_) {}
    }
    _activeSpec = null;
  }

  Future<void> unloadModel() => _closeLoadedModel();

  Stream<String> ask({
    required AiModelSpec spec,
    required String systemPrompt,
    required String userPrompt,
    int maxOutputTokens = aiMaxOutputTokens,
  }) async* {
    await loadModel(spec);
    final model = _model;
    if (model == null) {
      throw StateError('The offline AI model could not be loaded.');
    }
    final chat = await model.openChat(
      systemInstruction: systemPrompt,
      maxOutputTokens: maxOutputTokens,
      temperature: 0.2,
      topP: 0.9,
      topK: 40,
      enableThinking: false,
      modelType: spec.modelType,
    );
    _activeChat = chat;
    try {
      await chat.addQuery(Message.text(text: userPrompt, isUser: true));
      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse) {
          yield response.token;
        }
      }
    } finally {
      if (identical(_activeChat, chat)) _activeChat = null;
      try {
        await chat.close();
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    final chat = _activeChat;
    if (chat == null) return;
    try {
      await chat.stopGeneration();
    } catch (_) {}
  }

  Future<void> deleteModel(AiModelSpec spec) async {
    await initialize();
    if (_activeSpec?.id == spec.id) {
      await _closeLoadedModel();
    }
    for (final candidate in <String>{spec.registryName, spec.filename}) {
      try {
        await FlutterEdgeAi.uninstallModel(candidate);
      } catch (_) {}
    }
    await store.delete(spec);
    modelRevision.value++;
  }
}
