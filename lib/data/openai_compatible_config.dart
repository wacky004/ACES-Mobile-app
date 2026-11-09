import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpenAiCompatibleConfig extends ChangeNotifier {
  OpenAiCompatibleConfig._();
  static final OpenAiCompatibleConfig instance = OpenAiCompatibleConfig._();

  static const _keyStorage = 'compatible.apiKey';
  static const _baseUrlPref = 'compatible.baseUrl';
  static const _modelPref = 'compatible.modelId';
  static const _namePref = 'compatible.displayName';
  static const _visionPref = 'compatible.supportsVision';
  static const _jsonPref = 'compatible.supportsJson';
  static const _sharePref = 'compatible.shareHandoutContext';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  SharedPreferences? _prefs;
  String? _apiKey;
  String _baseUrl = 'https://openrouter.ai/api/v1';
  String _modelId = '';
  String _displayName = 'Custom cloud AI';
  bool _supportsVision = false;
  bool _supportsJson = true;
  bool _shareHandoutContext = false;
  bool _loaded = false;
  bool _loading = false;
  Future<void>? _loadFuture;

  bool get loaded => _loaded;
  bool get loading => _loading;
  bool get hasKey => (_apiKey ?? '').trim().isNotEmpty;
  String? get apiKey => _apiKey;
  String get baseUrl => _baseUrl;
  String get modelId => _modelId;
  String get displayName => _displayName;
  bool get supportsVision => _supportsVision;
  bool get supportsJson => _supportsJson;
  bool get shareHandoutContext => _shareHandoutContext;
  bool get isConfigured =>
      hasKey && _baseUrl.trim().isNotEmpty && _modelId.trim().isNotEmpty;

  String get chatUrl {
    final base = _baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.endsWith('/chat/completions')) return base;
    return '$base/chat/completions';
  }

  String get modelsUrl {
    final base = _baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.endsWith('/chat/completions')) {
      return '${base.substring(0, base.length - '/chat/completions'.length)}/models';
    }
    return '$base/models';
  }

  String get maskedKey {
    final key = (_apiKey ?? '').trim();
    if (key.isEmpty) return 'Not configured';
    if (key.length <= 8) return '********';
    return '${key.substring(0, 4)}****${key.substring(key.length - 4)}';
  }

  Future<void> load() {
    if (_loaded) return Future.value();
    final pending = _loadFuture;
    if (pending != null) return pending;
    final future = _load();
    _loadFuture = future;
    return future;
  }

  Future<void> _load() async {
    _loading = true;
    try {
      _apiKey = await _storage.read(key: _keyStorage);
      _prefs = await SharedPreferences.getInstance();
      _baseUrl = _prefs?.getString(_baseUrlPref) ?? _baseUrl;
      _modelId = _prefs?.getString(_modelPref) ?? '';
      _displayName = _prefs?.getString(_namePref) ?? _displayName;
      _supportsVision = _prefs?.getBool(_visionPref) ?? false;
      _supportsJson = _prefs?.getBool(_jsonPref) ?? true;
      _shareHandoutContext = _prefs?.getBool(_sharePref) ?? false;
    } catch (_) {
      _apiKey = null;
    } finally {
      _loading = false;
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> saveKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await clearKey();
      return;
    }
    await _storage.write(key: _keyStorage, value: trimmed);
    _apiKey = trimmed;
    _loaded = true;
    notifyListeners();
  }

  Future<void> clearKey() async {
    await _storage.delete(key: _keyStorage);
    _apiKey = null;
    _loaded = true;
    notifyListeners();
  }

  Future<void> saveSettings({
    required String baseUrl,
    required String modelId,
    required String displayName,
    required bool supportsVision,
    required bool supportsJson,
    required bool shareHandoutContext,
  }) async {
    _baseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    _modelId = modelId.trim();
    _displayName = displayName.trim().isEmpty ? 'Custom cloud AI' : displayName.trim();
    _supportsVision = supportsVision;
    _supportsJson = supportsJson;
    _shareHandoutContext = shareHandoutContext;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(_baseUrlPref, _baseUrl);
    await _prefs?.setString(_modelPref, _modelId);
    await _prefs?.setString(_namePref, _displayName);
    await _prefs?.setBool(_visionPref, _supportsVision);
    await _prefs?.setBool(_jsonPref, _supportsJson);
    await _prefs?.setBool(_sharePref, _shareHandoutContext);
    notifyListeners();
  }

  Future<void> setShareHandoutContext(bool value) async {
    _shareHandoutContext = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setBool(_sharePref, value);
    notifyListeners();
  }
}
