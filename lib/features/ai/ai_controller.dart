// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/chat_repository.dart';
import '../../data/deepseek_config.dart';
import '../../data/openai_compatible_config.dart';
import '../../data/pdf_repository.dart';
import '../../models/chat_session.dart';
import '../../models/deepseek_models.dart';
import '../../models/imported_pdf.dart';
import '../../services/ai/ai_config.dart';
import '../../services/ai/ai_model_catalog.dart';
import '../../services/ai/ai_service.dart';
import '../../services/ai/deepseek_service.dart';
import '../../services/ai/openai_compatible_service.dart';
import '../../services/ai/draft_quiz_service.dart';
import '../../services/ai/model_downloader.dart';
import '../../services/ai/model_store.dart';
import '../../services/ai/prompt_builder.dart';
import '../../services/ai/rag_index.dart';
import '../../services/pdf/pdf_attachment_service.dart';
import '../../services/pdf/pdf_import_service.dart';

class AiMessage {
  AiMessage({
    required this.isUser,
    required this.text,
    this.citations = const [],
    this.attachmentLabels = const [],
    this.isError = false,
    this.isStreaming = false,
    this.reasoning = '',
    this.providerLabel = '',
    this.usage,
  });

  final bool isUser;
  String text;
  final List<RagChunk> citations;
  final List<String> attachmentLabels;
  bool isError;
  bool isStreaming;
  String reasoning;
  final String providerLabel;
  DeepSeekUsage? usage;

  Map<String, dynamic> toJson() => {
    'isUser': isUser,
    'text': text,
    'citations': citations.map((chunk) => chunk.toJson()).toList(),
    'attachmentLabels': attachmentLabels,
    'isError': isError,
    'reasoning': reasoning,
    'providerLabel': providerLabel,
    if (usage != null) 'usage': usage!.toJson(),
  };

  factory AiMessage.fromJson(Map<String, dynamic> json) => AiMessage(
    isUser: json['isUser'] as bool? ?? false,
    text: json['text'] as String? ?? '',
    citations: (json['citations'] as List<dynamic>? ?? const [])
        .map((item) => RagChunk.fromJson((item as Map).cast<String, dynamic>()))
        .toList(growable: false),
    attachmentLabels: (json['attachmentLabels'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false),
    isError: json['isError'] as bool? ?? false,
    reasoning: json['reasoning'] as String? ?? '',
    providerLabel: json['providerLabel'] as String? ?? '',
    usage: json['usage'] is Map
        ? DeepSeekUsage.fromJson((json['usage'] as Map).cast<String, dynamic>())
        : null,
  );
}

class AiController extends ChangeNotifier {
  AiController({
    required this.pdfRepository,
    this.subjectId = 'it2205',
    ChatRepository? chatRepository,
    String? chatContextKey,
    String? pdfId,
  }) : _chatRepository = chatRepository,
       _chatContextKey = chatContextKey,
       _contextPdfId = pdfId;

  static final ValueNotifier<int> providerRevision = ValueNotifier(0);

  static const _selectedModelKey = 'ai.selectedModelId';
  static const _providerKey = 'ai.provider';
  static const _thinkingKey = 'ai.deepseekThinking';
  static const _maxInlineAttachmentBytes = 30 * 1024 * 1024;
  static const _maxAttachmentTextChars = 240000;

  final PdfRepository pdfRepository;
  final ChatRepository? _chatRepository;
  String? _chatContextKey;
  final String? _contextPdfId;
  String? _currentSessionId;
  DateTime _sessionCreatedAt = DateTime.now();
  List<AiChatSession> _chatSessions = const [];
  String subjectId;
  final ModelStore _store = ModelStore();
  final ModelDownloader _downloader = ModelDownloader();
  final PdfImportService _pdfImporter = PdfImportService();
  final PdfAttachmentService _pdfAttachments = PdfAttachmentService();
  final DraftQuizService _draftService = DraftQuizService();
  final DeepSeekConfig _deepSeekConfig = DeepSeekConfig.instance;
  final DeepSeekService _deepSeek = DeepSeekService();
  final OpenAiCompatibleConfig _compatibleConfig =
      OpenAiCompatibleConfig.instance;
  final OpenAiCompatibleService _compatible = OpenAiCompatibleService();

  RagIndex? _subjectIndex;
  final Map<String, RagIndex> _pdfIndexes = {};
  bool _bootstrapped = false;
  bool _revisionAttached = false;
  bool _providerAttached = false;
  bool _deepSeekAttached = false;
  bool _compatibleAttached = false;
  bool _disposed = false;
  bool _modelChecking = true;
  bool _downloading = false;
  bool _cancelDownload = false;
  int _downloadProgress = 0;
  String _downloadStatus = '';
  String? _downloadingModelId;
  String? _error;
  bool _isStreaming = false;
  bool _stopping = false;
  bool _useDeepSeek = false;
  bool _useCompatible = false;
  bool _deepSeekThinking = false;
  bool _preparingAttachment = false;
  bool _cancelAttachment = false;
  String _attachmentStatus = '';
  DeepSeekUsage? _lastUsage;
  Set<String> _termFilter = {};
  List<ImportedPdf> _pdfs = const [];
  List<DraftSet> _drafts = const [];
  Map<String, bool> _installed = {};
  Map<String, bool> _partials = {};
  String? _selectedModelId;
  int _installedBytes = 0;
  List<DeepSeekAttachment> _pendingAttachments = [];
  SharedPreferences? _prefs;

  final List<AiMessage> _messages = [];

  bool get modelChecking => _modelChecking;
  bool get downloading => _downloading;
  String? get downloadingModelId => _downloadingModelId;
  int get downloadProgress => _downloadProgress;
  String get downloadStatus => _downloadStatus;
  String? get error => _error;
  bool get isStreaming => _isStreaming;
  bool get usesDeepSeek => _useDeepSeek;
  bool get usesCompatible => _useCompatible;
  bool get usesCloud => _useDeepSeek || _useCompatible;
  bool get deepSeekThinking => _deepSeekThinking;
  bool get deepSeekReady => _deepSeekConfig.hasKey;
  bool get compatibleReady => _compatibleConfig.isConfigured;
  DeepSeekConfig get deepSeekConfig => _deepSeekConfig;
  DeepSeekModelSpec get deepSeekModel => _deepSeekConfig.model;
  OpenAiCompatibleConfig get compatibleConfig => _compatibleConfig;
  List<DeepSeekAttachment> get pendingAttachments =>
      List.unmodifiable(_pendingAttachments);
  int get _pendingInlineImageBytes => _pendingAttachments.fold(
    0,
    (total, attachment) => total + attachment.inlineImageBytes,
  );
  int get _pendingTextChars => _pendingAttachments.fold(
    0,
    (total, attachment) => total + attachment.textLength,
  );
  bool get preparingAttachment => _preparingAttachment;
  String get attachmentStatus => _attachmentStatus;
  DeepSeekUsage? get lastUsage => _lastUsage;
  List<AiMessage> get messages => List.unmodifiable(_messages);
  bool get sessionsEnabled =>
      _chatRepository != null && _chatContextKey != null;
  String? get currentSessionId => _currentSessionId;
  List<AiChatSession> get chatSessions => List.unmodifiable(_chatSessions);
  String get currentSessionTitle {
    for (final message in _messages) {
      if (!message.isUser) continue;
      final text = message.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isEmpty) continue;
      return text.length > 60 ? '${text.substring(0, 60)}...' : text;
    }
    return 'New chat';
  }

  List<ImportedPdf> get pdfs => List.unmodifiable(_pdfs);
  List<DraftSet> get drafts => List.unmodifiable(_drafts);
  Set<String> get termFilter => Set.unmodifiable(_termFilter);
  List<AiModelSpec> get catalog => aiModelCatalog;
  int get installedBytes => _installedBytes;

  AiModelSpec get selectedModel =>
      aiModelById(_selectedModelId) ?? defaultAiModel;

  bool get selectedModelInstalled => isInstalled(selectedModel);
  bool get modelInstalled => selectedModelInstalled;
  bool get isReady => _useCompatible
      ? compatibleReady
      : _useDeepSeek
      ? deepSeekReady
      : selectedModelInstalled;
  String get providerLabel => _useCompatible
      ? _compatibleConfig.displayName
      : _useDeepSeek
      ? deepSeekModel.displayName
      : selectedModel.displayName;
  bool get providerIsOnline => usesCloud;

  int get installedCount =>
      _installed.values.where((installed) => installed).length;

  bool isInstalled(AiModelSpec spec) => _installed[spec.id] ?? false;

  bool hasPartial(AiModelSpec spec) => _partials[spec.id] ?? false;

  bool isDownloadingModel(AiModelSpec spec) =>
      _downloading && _downloadingModelId == spec.id;

  Future<void> initialize() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    _modelChecking = true;
    _safeNotify();
    if (!_revisionAttached) {
      _revisionAttached = true;
      AiService.modelRevision.addListener(_onModelRevision);
    }
    if (!_providerAttached) {
      _providerAttached = true;
      providerRevision.addListener(_onProviderRevision);
    }
    if (!_deepSeekAttached) {
      _deepSeekAttached = true;
      _deepSeekConfig.addListener(_onDeepSeekChanged);
    }
    if (!_compatibleAttached) {
      _compatibleAttached = true;
      _compatibleConfig.addListener(_onCompatibleChanged);
    }
    try {
      await _deepSeekConfig.load();
      await _compatibleConfig.load();
      _prefs = await SharedPreferences.getInstance();
      final savedProvider = _prefs?.getString(_providerKey);
      _useDeepSeek = savedProvider == 'deepseek';
      _useCompatible = savedProvider == 'compatible';
      _deepSeekThinking = _prefs?.getBool(_thinkingKey) ?? false;
      _subjectIndex = await RagIndex.loadForSubject(subjectId);
      _pdfs = await pdfRepository.listPdfs();
      _drafts = await pdfRepository.listDrafts();
      await _restoreChatSession();
      await _reloadModels();
    } catch (error) {
      _error = 'AI could not be initialized: $error';
    } finally {
      _modelChecking = false;
      _safeNotify();
    }
  }

  void _onModelRevision() {
    _reloadModels();
  }

  void _onProviderRevision() {
    final stored = _prefs?.getString(_providerKey);
    if (stored == null) return;
    final nextDeepSeek = stored == 'deepseek';
    final nextCompatible = stored == 'compatible';
    if (nextDeepSeek == _useDeepSeek && nextCompatible == _useCompatible) {
      return;
    }
    _useDeepSeek = nextDeepSeek;
    _useCompatible = nextCompatible;
    if (!usesCloud) _pendingAttachments = [];
    _safeNotify();
  }

  void _onDeepSeekChanged() {
    if (_useDeepSeek &&
        _error != null &&
        (_error!.contains('API key') ||
            _error!.contains('Add a key') ||
            _error!.contains('Add your DeepSeek'))) {
      _error = null;
    }
    _safeNotify();
  }

  void _onCompatibleChanged() {
    if (_useCompatible && _compatibleConfig.isConfigured) {
      if (_error != null && _error!.contains('provider')) _error = null;
    }
    _safeNotify();
  }

  Future<void> _reloadModels() async {
    final installed = <String, bool>{};
    final partials = <String, bool>{};
    var bytes = 0;
    for (final spec in aiModelCatalog) {
      final isInstalled = await _store.isDownloaded(spec);
      installed[spec.id] = isInstalled;
      partials[spec.id] = await _store.hasPartial(spec);
      if (isInstalled) bytes += spec.sizeBytes;
    }
    _installed = installed;
    _partials = partials;
    _installedBytes = bytes;

    final stored = _prefs?.getString(_selectedModelKey);
    if (stored != null && aiModelById(stored) != null) {
      _selectedModelId = stored;
    } else {
      String? firstInstalled;
      for (final spec in aiModelCatalog) {
        if (installed[spec.id] == true) {
          firstInstalled = spec.id;
          break;
        }
      }
      _selectedModelId = firstInstalled ?? defaultAiModel.id;
    }
    _safeNotify();
  }

  Future<void> refreshModelStatus() => _reloadModels();

  Future<void> selectLocalProvider() async {
    if (_isStreaming) await stopStreaming();
    _useDeepSeek = false;
    _useCompatible = false;
    _pendingAttachments = [];
    await _prefs?.setString(_providerKey, 'local');
    _error = null;
    providerRevision.value++;
    _safeNotify();
  }

  Future<void> selectDeepSeekProvider({DeepSeekModelSpec? model}) async {
    await _deepSeekConfig.load();
    if (model != null) await _deepSeekConfig.setModel(model.id);
    if (_isStreaming) await stopStreaming();
    _useDeepSeek = true;
    _useCompatible = false;
    await _prefs?.setString(_providerKey, 'deepseek');
    _error = _deepSeekConfig.hasKey
        ? null
        : 'Add your DeepSeek API key in Settings to use the online tutor.';
    providerRevision.value++;
    _safeNotify();
  }

  Future<void> selectCompatibleProvider() async {
    await _compatibleConfig.load();
    if (_isStreaming) await stopStreaming();
    _useDeepSeek = false;
    _useCompatible = true;
    await _prefs?.setString(_providerKey, 'compatible');
    _error = _compatibleConfig.isConfigured
        ? null
        : 'Configure the OpenAI-compatible provider in Settings.';
    providerRevision.value++;
    _safeNotify();
  }

  Future<void> setDeepSeekThinking(bool enabled) async {
    _deepSeekThinking = enabled;
    await _prefs?.setBool(_thinkingKey, enabled);
    _safeNotify();
  }

  Future<void> selectModel(AiModelSpec spec) async {
    if (!isInstalled(spec)) {
      _error = '${spec.displayName} is not installed yet.';
      _safeNotify();
      return;
    }
    if (_isStreaming) await stopStreaming();
    try {
      await AiService.instance.ensureActive(spec);
      _selectedModelId = spec.id;
      _useDeepSeek = false;
      _useCompatible = false;
      await _prefs?.setString(_selectedModelKey, spec.id);
      await _prefs?.setString(_providerKey, 'local');
      _error = null;
      AiService.modelRevision.value++;
      providerRevision.value++;
    } catch (error) {
      _error = 'Could not switch models: $error';
    }
    _safeNotify();
  }

  Future<void> downloadModel(AiModelSpec spec) async {
    if (_downloading) return;
    if (isInstalled(spec)) {
      await selectModel(spec);
      return;
    }
    _downloading = true;
    _cancelDownload = false;
    _downloadingModelId = spec.id;
    _downloadProgress = 0;
    _downloadStatus = 'Preparing…';
    _error = null;
    _safeNotify();
    await WakelockPlus.enable();
    try {
      final file = await _downloader.download(
        spec,
        onProgress: (received, total, percent) {
          _downloadProgress = percent;
          _safeNotify();
        },
        onStatus: (status) {
          _downloadStatus = status;
          _safeNotify();
        },
        isCancelled: () => _cancelDownload,
      );
      await AiService.instance.ensureActive(spec);
      _selectedModelId = spec.id;
      await _prefs?.setString(_selectedModelKey, spec.id);
      _installed[spec.id] = true;
      _partials[spec.id] = false;
      _downloadStatus = 'Installed ${spec.displayName}';
      _downloadProgress = 100;
      _installedBytes = _installedBytes + spec.sizeBytes;
      _error = null;
      AiService.modelRevision.value++;
      debugPrint('Model installed at ${file.path}');
    } on ModelDownloadCancelled {
      _downloadStatus = 'Download paused';
      _error = null;
    } catch (error) {
      _error = 'Download failed: $error';
      _downloadStatus = 'Download failed';
    } finally {
      await WakelockPlus.disable();
      _downloading = false;
      _downloadingModelId = null;
      _safeNotify();
      await _reloadModels();
    }
  }

  void cancelDownload() {
    if (!_downloading) return;
    _cancelDownload = true;
    _downloadStatus = 'Pausing…';
    _safeNotify();
  }

  Future<void> deleteModel(AiModelSpec spec) async {
    if (isDownloadingModel(spec)) return;
    try {
      await AiService.instance.deleteModel(spec);
      _installed[spec.id] = false;
      _partials[spec.id] = false;
      if (_selectedModelId == spec.id) {
        String? next;
        for (final item in aiModelCatalog) {
          if (item.id != spec.id && isInstalled(item)) {
            next = item.id;
            break;
          }
        }
        _selectedModelId = next ?? defaultAiModel.id;
        await _prefs?.setString(_selectedModelKey, _selectedModelId!);
      }
      _error = null;
    } catch (error) {
      _error = 'Could not delete the model: $error';
    }
    await _reloadModels();
  }

  Future<bool> addImageAttachment(Uint8List bytes, String filename) async {
    if (!usesCloud) {
      _error = 'Switch to a cloud provider to attach photos.';
      _safeNotify();
      return false;
    }
    if (_useCompatible && !_compatibleConfig.supportsVision) {
      _error =
          'This custom cloud model is configured as text-only. '
          'Enable image support in its settings only if it accepts images.';
      _safeNotify();
      return false;
    }
    if (bytes.length > 32 * 1024 * 1024) {
      _error = 'This image is over 32 MB. Choose a smaller one.';
      _safeNotify();
      return false;
    }
    if (_pendingInlineImageBytes + bytes.length > _maxInlineAttachmentBytes) {
      _error =
          'The attached files are too large for one message. Remove a file '
          'or send them separately.';
      _safeNotify();
      return false;
    }
    if (_pendingAttachments.length >= 4) {
      _error = 'You can attach up to 4 files per message.';
      _safeNotify();
      return false;
    }
    if (_useDeepSeek && !_deepSeekConfig.model.supportsVision) {
      await _deepSeekConfig.setModel('deepseek-flash');
    }
    _pendingAttachments = [
      ..._pendingAttachments,
      DeepSeekAttachment(
        kind: DeepSeekAttachmentKind.image,
        filename: filename,
        bytes: bytes,
      ),
    ];
    _error = null;
    _safeNotify();
    return true;
  }

  void addTextAttachment(String text, String filename) {
    if (!usesCloud) {
      _error = 'Switch to a cloud provider to attach files.';
      _safeNotify();
      return;
    }
    if (text.trim().isEmpty || _pendingAttachments.length >= 4) return;
    final clipped = text.length > 120000
        ? '${text.substring(0, 120000)}…'
        : text;
    if (_pendingTextChars + clipped.length > _maxAttachmentTextChars) {
      _error =
          'The attached text is too large for one message. Remove a file '
          'or send it separately.';
      _safeNotify();
      return;
    }
    _pendingAttachments = [
      ..._pendingAttachments,
      DeepSeekAttachment(
        kind: DeepSeekAttachmentKind.text,
        filename: filename,
        text: clipped,
      ),
    ];
    _error = null;
    _safeNotify();
  }

  Future<bool> addPdfAttachment(Uint8List bytes, String filename) async {
    if (!usesCloud) {
      _error = 'Switch to a cloud provider to attach PDFs.';
      _safeNotify();
      return false;
    }
    if (_preparingAttachment) return false;
    if (_pendingAttachments.length >= 4) {
      _error = 'You can attach up to 4 files per message.';
      _safeNotify();
      return false;
    }
    _preparingAttachment = true;
    _cancelAttachment = false;
    _attachmentStatus = 'Reading PDF…';
    _error = null;
    _safeNotify();
    try {
      final attachment = await _pdfAttachments.prepare(
        bytes,
        filename,
        onProgress: (page, total, status) {
          _attachmentStatus = status;
          _safeNotify();
        },
        isCancelled: () => _cancelAttachment,
      );
      if (!usesCloud) {
        _error =
            'The cloud provider was switched off while preparing this PDF.';
        return false;
      }
      if (attachment.text == null && attachment.pageImages.isEmpty) {
        _error = 'No readable text or page images found in this PDF.';
        return false;
      }
      if (_useCompatible &&
          !_compatibleConfig.supportsVision &&
          attachment.pageImages.isNotEmpty) {
        _error =
            'This custom cloud model is text-only. Use a PDF with '
            'selectable text, switch to DeepSeek Flash, or use local AI.';
        return false;
      }
      if (_pendingInlineImageBytes + attachment.inlineImageBytes >
          _maxInlineAttachmentBytes) {
        _error =
            'The attached files are too large for one message. Remove a file '
            'or send this PDF separately.';
        return false;
      }
      if (_pendingTextChars + attachment.textLength > _maxAttachmentTextChars) {
        _error =
            'The attached text is too large for one message. Remove a file '
            'or send this PDF separately.';
        return false;
      }
      if (_useDeepSeek &&
          attachment.pageImages.isNotEmpty &&
          !_deepSeekConfig.model.supportsVision) {
        await _deepSeekConfig.setModel('deepseek-flash');
      }
      _pendingAttachments = [..._pendingAttachments, attachment];
      _attachmentStatus = 'Ready to send';
      _error = null;
      return true;
    } on PdfAttachmentCancelled {
      _attachmentStatus = 'Cancelled';
      return false;
    } on PdfAttachmentException catch (error) {
      _error = error.message;
      return false;
    } catch (error) {
      _error = 'Could not prepare this PDF: $error';
      return false;
    } finally {
      _preparingAttachment = false;
      _safeNotify();
    }
  }

  void cancelAttachmentPreparation() {
    if (!_preparingAttachment) return;
    _cancelAttachment = true;
    _attachmentStatus = 'Cancelling…';
    _safeNotify();
  }

  void removeAttachment(int index) {
    if (index < 0 || index >= _pendingAttachments.length) return;
    _pendingAttachments = [..._pendingAttachments]..removeAt(index);
    _safeNotify();
  }

  void clearAttachments() {
    _pendingAttachments = [];
    _safeNotify();
  }

  void setTermFilter(Set<String> termIds) {
    _termFilter = Set.of(termIds);
    _safeNotify();
  }

  String _newSessionId() => 'chat-${DateTime.now().microsecondsSinceEpoch}';

  DeepSeekUsage? _lastUsageFromMessages() {
    for (final message in _messages.reversed) {
      if (message.usage != null) return message.usage;
    }
    return null;
  }

  Future<void> _restoreChatSession() async {
    final repository = _chatRepository;
    final contextKey = _chatContextKey;
    if (repository == null || contextKey == null) return;
    final session = await repository.latestForContext(contextKey);
    if (session == null || session.messages.isEmpty) {
      _currentSessionId = _newSessionId();
      _sessionCreatedAt = DateTime.now();
      return;
    }
    _messages
      ..clear()
      ..addAll(session.messages.map(AiMessage.fromJson));
    _currentSessionId = session.id;
    _sessionCreatedAt = session.createdAt;
    _lastUsage = _lastUsageFromMessages();
  }

  Future<void> _persistChatSession() async {
    final repository = _chatRepository;
    final contextKey = _chatContextKey;
    if (repository == null || contextKey == null || _messages.isEmpty) return;
    final id = _currentSessionId ?? _newSessionId();
    _currentSessionId = id;
    final session = AiChatSession(
      id: id,
      subjectId: subjectId,
      contextKey: contextKey,
      pdfId: _contextPdfId,
      title: currentSessionTitle,
      createdAt: _sessionCreatedAt,
      updatedAt: DateTime.now(),
      messages: _messages.map((message) => message.toJson()).toList(),
    );
    await repository.save(session);
    await refreshChatSessions(notify: false);
  }

  Future<void> startNewSession() async {
    await _persistChatSession();
    if (_isStreaming) await stopStreaming();
    _messages.clear();
    _pendingAttachments = [];
    _lastUsage = null;
    _error = null;
    _currentSessionId = _newSessionId();
    _sessionCreatedAt = DateTime.now();
    _safeNotify();
  }

  Future<void> openSession(String id) async {
    final repository = _chatRepository;
    if (repository == null) return;
    await _persistChatSession();
    final session = await repository.get(id);
    if (session == null) return;
    if (_isStreaming) await stopStreaming();
    _messages
      ..clear()
      ..addAll(session.messages.map(AiMessage.fromJson));
    _currentSessionId = session.id;
    _sessionCreatedAt = session.createdAt;
    _lastUsage = _lastUsageFromMessages();
    _error = null;
    _safeNotify();
  }

  Future<List<AiChatSession>> refreshChatSessions({bool notify = true}) async {
    final repository = _chatRepository;
    final contextKey = _chatContextKey;
    if (repository == null || contextKey == null) return const [];
    _chatSessions = await repository.listForContext(contextKey);
    if (notify) _safeNotify();
    return _chatSessions;
  }

  Future<void> deleteChatSession(String id) async {
    final repository = _chatRepository;
    if (repository == null) return;
    await repository.delete(id);
    if (id == _currentSessionId) {
      _messages.clear();
      _lastUsage = null;
      _currentSessionId = _newSessionId();
      _sessionCreatedAt = DateTime.now();
    }
    await refreshChatSessions(notify: false);
    _safeNotify();
  }

  void clearChat() {
    unawaited(startNewSession());
  }

  Future<void> stopStreaming() async {
    _stopping = true;
    await _deepSeek.stop();
    await _compatible.stop();
    await AiService.instance.stop();
  }

  Future<void> ask(String text, {String? pdfId}) async {
    var question = text.trim();
    if (question.isEmpty && _pendingAttachments.isNotEmpty) {
      question = 'Explain the attached file(s).';
    }
    if (question.isEmpty || _isStreaming) return;

    if (_useDeepSeek) {
      if (!_deepSeekConfig.hasKey) {
        _error = 'Add your DeepSeek API key in Settings first.';
        _safeNotify();
        return;
      }
      final useCloudContext =
          pdfId != null || _deepSeekConfig.shareHandoutContext;
      final chunks = useCloudContext
          ? await retrieve(question, pdfId: pdfId)
          : const <RagChunk>[];
      final prompt = useCloudContext
          ? (chunks.isEmpty
                ? '$question\n\nNo handout excerpts were retrieved. Answer from '
                      'general knowledge, say when you are unsure, and do not '
                      'invent a handout citation.'
                : PromptBuilder.chatPrompt(
                    userMessage: question,
                    chunks: chunks,
                    history: const [],
                  ))
          : question;
      final attachments = List<DeepSeekAttachment>.of(_pendingAttachments);
      _pendingAttachments = [];
      await _runDeepSeekPrompt(
        displayText: question,
        prompt: prompt,
        citations: chunks,
        attachments: attachments,
      );
      return;
    }

    if (_useCompatible) {
      if (!_compatibleConfig.isConfigured) {
        _error = 'Configure the OpenAI-compatible provider in Settings first.';
        _safeNotify();
        return;
      }
      final useCloudContext =
          pdfId != null || _compatibleConfig.shareHandoutContext;
      final chunks = useCloudContext
          ? await retrieve(question, pdfId: pdfId)
          : const <RagChunk>[];
      final prompt = useCloudContext
          ? (chunks.isEmpty
                ? '$question\n\nNo handout excerpts were retrieved. Answer from '
                      'general knowledge, say when you are unsure, and do not '
                      'invent a handout citation.'
                : PromptBuilder.chatPrompt(
                    userMessage: question,
                    chunks: chunks,
                    history: const [],
                  ))
          : question;
      final attachments = List<DeepSeekAttachment>.of(_pendingAttachments);
      _pendingAttachments = [];
      await _runCompatiblePrompt(
        displayText: question,
        prompt: prompt,
        citations: chunks,
        attachments: attachments,
      );
      return;
    }

    if (_pendingAttachments.isNotEmpty) {
      _error =
          'Attachments require a cloud provider. Remove them or switch provider.';
      _safeNotify();
      return;
    }
    final chunks = await retrieve(question, pdfId: pdfId);
    await _runPrompt(
      displayText: question,
      prompt: PromptBuilder.chatPrompt(
        userMessage: question,
        chunks: chunks,
        history: _historyForPrompt(),
      ),
      citations: chunks,
    );
  }

  Future<void> askAboutQuestion({
    required String question,
    required List<String> options,
    required int answerIndex,
    required String explanation,
    required String topic,
    required String handoutTitle,
    required int sourcePage,
  }) async {
    if (_isStreaming) return;
    final includeContext = _useDeepSeek
        ? _deepSeekConfig.shareHandoutContext
        : _useCompatible
        ? _compatibleConfig.shareHandoutContext
        : true;
    final chunks = includeContext
        ? await retrieve('$question $topic', pdfId: null)
        : const <RagChunk>[];
    final prompt =
        '${PromptBuilder.questionPrompt(question: question, options: options, answerIndex: answerIndex, explanation: explanation, chunks: chunks, topic: topic, citeHandout: chunks.isNotEmpty)}\n\nThe quiz item comes from $handoutTitle, page $sourcePage.';
    if (_useDeepSeek) {
      if (!_deepSeekConfig.hasKey) {
        _error = 'Add your DeepSeek API key in Settings first.';
        _safeNotify();
        return;
      }
      await _runDeepSeekPrompt(
        displayText:
            'Explain this item ($handoutTitle · page $sourcePage): $question',
        prompt: prompt,
        citations: chunks,
        attachments: const [],
      );
      return;
    }
    if (_useCompatible) {
      if (!_compatibleConfig.isConfigured) {
        _error = 'Configure the OpenAI-compatible provider in Settings first.';
        _safeNotify();
        return;
      }
      await _runCompatiblePrompt(
        displayText:
            'Explain this item ($handoutTitle - page $sourcePage): $question',
        prompt: prompt,
        citations: chunks,
        attachments: const [],
      );
      return;
    }
    await _runPrompt(
      displayText:
          'Explain this item ($handoutTitle · page $sourcePage): $question',
      prompt: prompt,
      citations: chunks,
    );
  }

  Future<void> switchSubject(
    String nextSubjectId, {
    String? chatContextKey,
  }) async {
    if (nextSubjectId == subjectId && chatContextKey == null) return;
    await _persistChatSession();
    subjectId = nextSubjectId;
    if (chatContextKey != null) _chatContextKey = chatContextKey;
    _subjectIndex = await RagIndex.loadForSubject(nextSubjectId);
    _messages.clear();
    _pendingAttachments = [];
    _lastUsage = null;
    _error = null;
    await _restoreChatSession();
    _safeNotify();
  }

  Future<List<RagChunk>> retrieve(String query, {String? pdfId}) async {
    if (pdfId != null) {
      final index = _pdfIndexes[pdfId] ?? _buildPdfIndex(pdfId);
      if (index != null) return index.search(query, limit: 4);
    }
    final index = _subjectIndex;
    if (index == null) return const [];
    return index.search(query, termIds: _termFilter, limit: 4);
  }

  RagIndex? _buildPdfIndex(String pdfId) {
    for (final pdf in _pdfs) {
      if (pdf.id != pdfId) continue;
      final chunks = pdf.chunks
          .map((chunk) => RagChunk.fromPdfChunk(pdf, chunk))
          .toList(growable: false);
      final index = RagIndex.fromChunks(chunks);
      _pdfIndexes[pdfId] = index;
      return index;
    }
    return null;
  }

  Future<void> _runPrompt({
    required String displayText,
    required String prompt,
    required List<RagChunk> citations,
  }) async {
    final model = selectedModel;
    if (!isInstalled(model)) {
      _error = 'Download an offline model from Models first.';
      _safeNotify();
      return;
    }
    _messages.add(AiMessage(isUser: true, text: displayText));
    final assistant = AiMessage(
      isUser: false,
      text: '',
      citations: citations,
      isStreaming: true,
      providerLabel: selectedModel.displayName,
    );
    _messages.add(assistant);
    _isStreaming = true;
    _error = null;
    _safeNotify();

    try {
      await for (final token in AiService.instance.ask(
        spec: model,
        systemPrompt: PromptBuilder.systemPrompt,
        userPrompt: prompt,
        maxOutputTokens: aiMaxOutputTokens,
      )) {
        if (_disposed) break;
        assistant.text += token;
        _safeNotify();
      }
    } catch (error) {
      assistant.isError = true;
      assistant.text = assistant.text.isEmpty
          ? 'The offline model could not answer: $error'
          : '${assistant.text}\n\n[Generation stopped: $error]';
    } finally {
      assistant.isStreaming = false;
      _isStreaming = false;
      await _persistChatSession();
      _safeNotify();
    }
  }

  Future<void> _runDeepSeekPrompt({
    required String displayText,
    required String prompt,
    required List<RagChunk> citations,
    required List<DeepSeekAttachment> attachments,
  }) async {
    if (!_deepSeekConfig.hasKey) {
      _error = 'Add your DeepSeek API key in Settings first.';
      _safeNotify();
      return;
    }
    if (attachments.any((item) => item.hasImages) &&
        !_deepSeekConfig.model.supportsVision) {
      await _deepSeekConfig.setModel('deepseek-flash');
    }
    final history = _historyForPrompt();
    _messages.add(
      AiMessage(
        isUser: true,
        text: displayText,
        attachmentLabels: [
          for (final attachment in attachments) attachment.label,
        ],
      ),
    );
    final assistant = AiMessage(
      isUser: false,
      text: '',
      citations: citations,
      isStreaming: true,
      providerLabel: _deepSeekConfig.model.displayName,
    );
    _messages.add(assistant);
    _isStreaming = true;
    _stopping = false;
    _error = null;
    _lastUsage = null;
    _safeNotify();

    try {
      await for (final chunk in _deepSeek.chat(
        model: _deepSeekConfig.model,
        systemPrompt: PromptBuilder.deepSeekSystemPrompt,
        userPrompt: prompt,
        history: history,
        attachments: attachments,
        thinking: _deepSeekThinking,
        jsonMode: false,
        maxOutputTokens: 2400,
      )) {
        if (_disposed) break;
        if (chunk.reasoning != null) {
          assistant.reasoning += chunk.reasoning!;
        }
        if (chunk.content != null) {
          assistant.text += chunk.content!;
        }
        if (chunk.usage != null) {
          assistant.usage = chunk.usage;
          _lastUsage = chunk.usage;
        }
        _safeNotify();
      }
    } catch (error) {
      if (!_stopping) {
        assistant.isError = true;
        assistant.text = assistant.text.isEmpty
            ? '$error'
            : '${assistant.text}\n\n[Stopped: $error]';
        _error = '$error';
      }
    } finally {
      if (!assistant.isError &&
          assistant.text.trim().isEmpty &&
          assistant.reasoning.trim().isNotEmpty) {
        assistant.text =
            'The model used all of its output tokens for reasoning before '
            'writing an answer. Turn off Thinking or ask a shorter question.';
      }
      assistant.isStreaming = false;
      _isStreaming = false;
      _stopping = false;
      await _persistChatSession();
      _safeNotify();
    }
  }

  Future<void> _runCompatiblePrompt({
    required String displayText,
    required String prompt,
    required List<RagChunk> citations,
    required List<DeepSeekAttachment> attachments,
  }) async {
    if (!_compatibleConfig.isConfigured) {
      _error = 'Configure the OpenAI-compatible provider in Settings first.';
      _safeNotify();
      return;
    }
    final history = _historyForPrompt();
    _messages.add(
      AiMessage(
        isUser: true,
        text: displayText,
        attachmentLabels: [
          for (final attachment in attachments) attachment.label,
        ],
      ),
    );
    final assistant = AiMessage(
      isUser: false,
      text: '',
      citations: citations,
      isStreaming: true,
      providerLabel: _compatibleConfig.displayName,
    );
    _messages.add(assistant);
    _isStreaming = true;
    _stopping = false;
    _error = null;
    _lastUsage = null;
    _safeNotify();
    try {
      await for (final chunk in _compatible.chat(
        systemPrompt: PromptBuilder.deepSeekSystemPrompt,
        userPrompt: prompt,
        history: history,
        attachments: attachments,
        jsonMode: false,
        maxOutputTokens: 2400,
      )) {
        if (_disposed) break;
        if (chunk.reasoning != null) assistant.reasoning += chunk.reasoning!;
        if (chunk.content != null) assistant.text += chunk.content!;
        if (chunk.usage != null) {
          assistant.usage = chunk.usage;
          _lastUsage = chunk.usage;
        }
        _safeNotify();
      }
    } catch (error) {
      if (!_stopping) {
        assistant.isError = true;
        assistant.text = assistant.text.isEmpty
            ? '$error'
            : '${assistant.text}\n\n[Stopped: $error]';
        _error = '$error';
      }
    } finally {
      assistant.isStreaming = false;
      _isStreaming = false;
      _stopping = false;
      await _persistChatSession();
      _safeNotify();
    }
  }

  List<ChatTurn> _historyForPrompt() {
    final turns = <ChatTurn>[];
    final start = _messages.length > 8 ? _messages.length - 8 : 0;
    for (var index = start; index < _messages.length; index++) {
      final message = _messages[index];
      if (message.isError || message.isStreaming) continue;
      turns.add(ChatTurn(isUser: message.isUser, text: message.text));
    }
    return turns;
  }

  Future<ImportedPdf> importPdf(
    Uint8List bytes,
    String filename, {
    required void Function(int progress, String status) onProgress,
    bool Function()? isCancelled,
  }) async {
    final pdf = await _pdfImporter.extract(
      bytes,
      filename,
      onProgress: onProgress,
      isCancelled: isCancelled,
    );
    await pdfRepository.savePdf(pdf);
    _pdfs = await pdfRepository.listPdfs();
    _safeNotify();
    return pdf;
  }

  Future<void> deletePdf(String id) async {
    await pdfRepository.deletePdf(id);
    await _chatRepository?.deleteForPdf(id);
    _pdfIndexes.remove(id);
    _pdfs = await pdfRepository.listPdfs();
    _drafts = await pdfRepository.listDrafts();
    _safeNotify();
  }

  Future<void> deleteDraft(String id) async {
    await pdfRepository.deleteDraft(id);
    _drafts = await pdfRepository.listDrafts();
    _safeNotify();
  }

  Future<DraftSet> generateDraft(
    ImportedPdf pdf, {
    int count = 10,
    bool useDeepSeek = false,
    bool useCompatible = false,
    required void Function(int completed, int total, String status) onProgress,
    bool Function()? isCancelled,
  }) async {
    final index = _pdfIndexes[pdf.id] ?? _buildPdfIndex(pdf.id);
    final chunks = index?.chunks ?? const <RagChunk>[];
    if (useCompatible) {
      onProgress(0, count, 'Contacting ${_compatibleConfig.displayName}...');
    } else if (!useDeepSeek) {
      final model = selectedModel;
      if (!isInstalled(model)) {
        throw StateError('Download an offline model from Models first.');
      }
      onProgress(0, count, 'Loading ${model.displayName}...');
      await AiService.instance.loadModel(model);
      onProgress(0, count, 'Model ready. Generating questions...');
    } else {
      onProgress(0, count, 'Contacting DeepSeek...');
    }
    final questions = useCompatible
        ? await _generateDraftCompatible(
            pdf: pdf,
            chunks: chunks,
            count: count,
            onProgress: onProgress,
            isCancelled: isCancelled,
          )
        : useDeepSeek
        ? await _generateDraftDeepSeek(
            pdf: pdf,
            chunks: chunks,
            count: count,
            onProgress: onProgress,
            isCancelled: isCancelled,
          )
        : await _draftService.generate(
            model: selectedModel,
            pdf: pdf,
            chunks: chunks,
            count: count,
            onProgress: onProgress,
            isCancelled: isCancelled,
          );
    final draft = DraftSet(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      pdfId: pdf.id,
      filename: pdf.filename,
      createdAt: DateTime.now(),
      questions: questions,
    );
    await pdfRepository.saveDraft(draft);
    _drafts = await pdfRepository.listDrafts();
    _safeNotify();
    return draft;
  }

  Future<List<DraftQuestion>> _generateDraftCompatible({
    required ImportedPdf pdf,
    required List<RagChunk> chunks,
    required int count,
    required void Function(int completed, int total, String status) onProgress,
    bool Function()? isCancelled,
  }) async {
    if (!_compatibleConfig.isConfigured) {
      throw const DeepSeekException(
        'Configure the OpenAI-compatible provider in Settings first.',
      );
    }
    if (chunks.isEmpty) return const [];
    final batch = <RagChunk>[];
    final desired = chunks.length < 16 ? chunks.length : 16;
    for (var i = 0; i < desired; i++) {
      batch.add(chunks[(i * chunks.length / desired).floor()]);
    }
    onProgress(0, count, 'Waiting for ${_compatibleConfig.displayName}...');
    final buffer = StringBuffer();
    var received = false;
    await for (final chunk in _compatible.chat(
      systemPrompt: PromptBuilder.draftSystemPrompt,
      userPrompt: PromptBuilder.draftPrompt(
        chunks: batch,
        count: count,
        jsonObject: true,
      ),
      jsonMode: _compatibleConfig.supportsJson,
      maxOutputTokens: 4000,
    )) {
      if (isCancelled?.call() ?? false) {
        await _compatible.stop();
        break;
      }
      if (chunk.content != null) {
        if (!received) {
          received = true;
          onProgress(0, count, 'Writing the JSON response...');
        }
        buffer.write(chunk.content);
      }
    }
    final parsed = DraftQuizService().parseQuestions(buffer.toString(), batch);
    final now = DateTime.now().microsecondsSinceEpoch;
    final result = <DraftQuestion>[];
    for (var index = 0; index < parsed.length && index < count; index++) {
      final question = parsed[index];
      result.add(
        DraftQuestion(
          id: '${pdf.id}-$now-$index',
          sourcePage: question.sourcePage,
          topic: question.topic,
          difficulty: question.difficulty,
          stem: question.stem,
          options: question.options,
          answerIndex: question.answerIndex,
          explanation: question.explanation,
        ),
      );
    }
    onProgress(result.length, count, 'Generated ${result.length} of $count');
    return result;
  }

  Future<List<DraftQuestion>> _generateDraftDeepSeek({
    required ImportedPdf pdf,
    required List<RagChunk> chunks,
    required int count,
    required void Function(int completed, int total, String status) onProgress,
    bool Function()? isCancelled,
  }) async {
    if (!_deepSeekConfig.hasKey) {
      throw const DeepSeekException(
        'Add a DeepSeek API key in Settings first.',
      );
    }
    if (chunks.isEmpty) return const [];
    final batch = <RagChunk>[];
    final desired = chunks.length < 16 ? chunks.length : 16;
    for (var i = 0; i < desired; i++) {
      batch.add(chunks[(i * chunks.length / desired).floor()]);
    }
    onProgress(0, count, 'Waiting for DeepSeek…');
    final buffer = StringBuffer();
    var receivedContent = false;
    await for (final chunk in _deepSeek.chat(
      model: _deepSeekConfig.model,
      systemPrompt: PromptBuilder.draftSystemPrompt,
      userPrompt: PromptBuilder.draftPrompt(
        chunks: batch,
        count: count,
        jsonObject: true,
      ),
      jsonMode: true,
      thinking: false,
      maxOutputTokens: 4000,
    )) {
      if (isCancelled?.call() ?? false) {
        await _deepSeek.stop();
        break;
      }
      if (chunk.content != null) {
        if (!receivedContent) {
          receivedContent = true;
          onProgress(0, count, 'DeepSeek is writing the JSON response...');
        }
        buffer.write(chunk.content);
      }
    }
    final parsed = DraftQuizService().parseQuestions(buffer.toString(), batch);
    final now = DateTime.now().microsecondsSinceEpoch;
    final result = <DraftQuestion>[];
    for (var index = 0; index < parsed.length && index < count; index++) {
      final question = parsed[index];
      result.add(
        DraftQuestion(
          id: '${pdf.id}-$now-$index',
          sourcePage: question.sourcePage,
          topic: question.topic,
          difficulty: question.difficulty,
          stem: question.stem,
          options: question.options,
          answerIndex: question.answerIndex,
          explanation: question.explanation,
        ),
      );
    }
    onProgress(result.length, count, 'Generated ${result.length} of $count');
    return result;
  }

  Future<void> cancelDraft() async {
    await _deepSeek.stop();
    await _compatible.stop();
    await AiService.instance.stop();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_persistChatSession());
    if (_revisionAttached) {
      AiService.modelRevision.removeListener(_onModelRevision);
    }
    if (_providerAttached) {
      providerRevision.removeListener(_onProviderRevision);
    }
    if (_deepSeekAttached) {
      _deepSeekConfig.removeListener(_onDeepSeekChanged);
    }
    if (_compatibleAttached) {
      _compatibleConfig.removeListener(_onCompatibleChanged);
    }
    _deepSeek.stop();
    _compatible.stop();
    AiService.instance.stop();
    super.dispose();
  }
}
