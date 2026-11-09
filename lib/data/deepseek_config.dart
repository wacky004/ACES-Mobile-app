import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/deepseek_models.dart';

class DeepSeekConfig extends ChangeNotifier {
  DeepSeekConfig._();
  static final DeepSeekConfig instance = DeepSeekConfig._();

  static const _keyStorage = 'deepseek.apiKey';
  static const _modelPref = 'deepseek.modelId';
  static const _sharePref = 'deepseek.shareHandoutContext';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  SharedPreferences? _prefs;
  String? _apiKey;
  String _modelId = 'deepseek-flash';
  bool _shareHandoutContext = false;
  bool _loaded = false;
  bool _loading = false;
  Future<void>? _loadFuture;

  bool get loaded => _loaded;
  bool get loading => _loading;
  bool get hasKey => (_apiKey ?? '').trim().isNotEmpty;
  String? get apiKey => _apiKey;
  DeepSeekModelSpec get model => deepSeekModelById(_modelId);
  bool get shareHandoutContext => _shareHandoutContext;

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
      _modelId = _prefs?.getString(_modelPref) ?? 'deepseek-flash';
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

  Future<void> setModel(String id) async {
    _modelId = deepSeekModelById(id).id;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(_modelPref, _modelId);
    notifyListeners();
  }

  Future<void> setShareHandoutContext(bool value) async {
    _shareHandoutContext = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setBool(_sharePref, value);
    notifyListeners();
  }

  String get maskedKey {
    final key = (_apiKey ?? '').trim();
    if (key.isEmpty) return 'Not configured';
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}••••••${key.substring(key.length - 4)}';
  }
}
