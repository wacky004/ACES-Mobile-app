import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cloud_profile.dart';

class OpenAiCompatibleConfig extends ChangeNotifier {
  OpenAiCompatibleConfig._();
  static final OpenAiCompatibleConfig instance = OpenAiCompatibleConfig._();

  static const _profilesPref = 'compatible.profiles';
  static const _activePref = 'compatible.activeProfileId';
  static const _legacyKeyStorage = 'compatible.apiKey';
  static const _legacyBaseUrlPref = 'compatible.baseUrl';
  static const _legacyModelPref = 'compatible.modelId';
  static const _legacyNamePref = 'compatible.displayName';
  static const _legacyVisionPref = 'compatible.supportsVision';
  static const _legacyJsonPref = 'compatible.supportsJson';
  static const _legacySharePref = 'compatible.shareHandoutContext';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  SharedPreferences? _prefs;
  List<CloudProfile> _profiles = const [];
  String? _activeId;
  final Map<String, String> _keys = {};
  bool _loaded = false;
  bool _loading = false;
  Future<void>? _loadFuture;

  bool get loaded => _loaded;
  bool get loading => _loading;
  List<CloudProfile> get profiles => List.unmodifiable(_profiles);
  String? get activeProfileId => _activeId;
  CloudProfile? get activeProfile => profileById(_activeId);
  bool get hasProfiles => _profiles.isNotEmpty;
  bool get hasKey => _activeKey.trim().isNotEmpty;
  String? get apiKey => _activeKey;
  String get baseUrl => activeProfile?.baseUrl ?? '';
  String get modelId => activeProfile?.modelId ?? '';
  String get displayName => activeProfile?.displayName ?? 'Custom cloud AI';
  bool get supportsVision => activeProfile?.supportsVision ?? false;
  bool get supportsJson => activeProfile?.supportsJson ?? true;
  bool get shareHandoutContext => activeProfile?.shareHandoutContext ?? false;
  bool get isConfigured =>
      activeProfile != null &&
      hasKey &&
      baseUrl.trim().isNotEmpty &&
      modelId.trim().isNotEmpty;

  String get _activeKey => _activeId == null ? '' : (_keys[_activeId!] ?? '');

  String get chatUrl => activeProfile?.chatUrl ?? '';
  String get modelsUrl => activeProfile?.modelsUrl ?? '';

  String get maskedKey {
    final key = _activeKey.trim();
    if (key.isEmpty) return 'Not configured';
    if (key.length <= 8) return '********';
    return '${key.substring(0, 4)}****${key.substring(key.length - 4)}';
  }

  CloudProfile? profileById(String? id) {
    if (id == null) return null;
    for (final profile in _profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  String keyFor(String profileId) => _keys[profileId] ?? '';

  String maskedKeyFor(String profileId) {
    final key = keyFor(profileId).trim();
    if (key.isEmpty) return 'No key';
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
      _prefs = await SharedPreferences.getInstance();
      final rawProfiles = _prefs?.getString(_profilesPref);
      if (rawProfiles != null && rawProfiles.trim().isNotEmpty) {
        final decoded = jsonDecode(rawProfiles);
        if (decoded is List) {
          _profiles = decoded
              .whereType<Map>()
              .map(
                (item) => CloudProfile.fromJson(item.cast<String, dynamic>()),
              )
              .toList(growable: false);
        }
      }
      _activeId = _prefs?.getString(_activePref);
      await _migrateLegacyProfile();
      if (_profiles.isNotEmpty) {
        if (profileById(_activeId) == null) {
          _activeId = _profiles.first.id;
        }
        for (final profile in _profiles) {
          final key = await _storage.read(key: _storageKey(profile.id));
          if (key != null && key.trim().isNotEmpty) {
            _keys[profile.id] = key.trim();
          }
        }
      } else {
        _activeId = null;
      }
    } catch (_) {
      _profiles = const [];
      _activeId = null;
    } finally {
      _loading = false;
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _migrateLegacyProfile() async {
    if (_profiles.isNotEmpty) return;
    final legacyKey = (await _storage.read(key: _legacyKeyStorage))?.trim();
    final baseUrl = _prefs?.getString(_legacyBaseUrlPref);
    final modelId = _prefs?.getString(_legacyModelPref);
    if ((legacyKey == null || legacyKey.isEmpty) &&
        (baseUrl == null || baseUrl.isEmpty) &&
        (modelId == null || modelId.isEmpty)) {
      return;
    }
    final now = DateTime.now();
    final profile = CloudProfile(
      id: 'legacy-${now.microsecondsSinceEpoch}',
      displayName: _prefs?.getString(_legacyNamePref) ?? 'Default custom cloud',
      baseUrl: baseUrl ?? 'https://openrouter.ai/api/v1',
      modelId: modelId ?? '',
      supportsVision: _prefs?.getBool(_legacyVisionPref) ?? false,
      supportsJson: _prefs?.getBool(_legacyJsonPref) ?? true,
      shareHandoutContext: _prefs?.getBool(_legacySharePref) ?? false,
      createdAt: now,
      updatedAt: now,
    );
    _profiles = [profile];
    _activeId = profile.id;
    if (legacyKey != null && legacyKey.isNotEmpty) {
      await _storage.write(key: _storageKey(profile.id), value: legacyKey);
    }
    await _persistProfiles();
    await _prefs?.setString(_activePref, profile.id);
    await _storage.delete(key: _legacyKeyStorage);
  }

  Future<void> createProfile({
    String displayName = 'New cloud profile',
    String baseUrl = 'https://openrouter.ai/api/v1',
    String modelId = '',
    bool supportsVision = false,
    bool supportsJson = true,
    bool shareHandoutContext = false,
    String? key,
  }) async {
    final now = DateTime.now();
    final profile = CloudProfile(
      id: 'cloud-${now.microsecondsSinceEpoch}',
      displayName: displayName.trim().isEmpty
          ? 'New cloud profile'
          : displayName.trim(),
      baseUrl: baseUrl.trim(),
      modelId: modelId.trim(),
      supportsVision: supportsVision,
      supportsJson: supportsJson,
      shareHandoutContext: shareHandoutContext,
      createdAt: now,
      updatedAt: now,
    );
    _profiles = [..._profiles, profile];
    _activeId = profile.id;
    if (key != null && key.trim().isNotEmpty) {
      await _storage.write(key: _storageKey(profile.id), value: key.trim());
      _keys[profile.id] = key.trim();
    }
    await _persistProfiles();
    await _prefs?.setString(_activePref, profile.id);
    notifyListeners();
  }

  Future<void> selectProfile(String id) async {
    if (profileById(id) == null) return;
    _activeId = id;
    await _prefs?.setString(_activePref, id);
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    final profile = profileById(id);
    if (profile == null) return;
    _profiles = _profiles
        .where((item) => item.id != id)
        .toList(growable: false);
    _keys.remove(id);
    await _storage.delete(key: _storageKey(id));
    if (_activeId == id) {
      _activeId = _profiles.isEmpty ? null : _profiles.first.id;
      if (_activeId != null) {
        await _prefs?.setString(_activePref, _activeId!);
      } else {
        await _prefs?.remove(_activePref);
      }
    }
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> saveKey(String key) async {
    final active = activeProfile;
    if (active == null) return;
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await clearKey();
      return;
    }
    await _storage.write(key: _storageKey(active.id), value: trimmed);
    _keys[active.id] = trimmed;
    _loaded = true;
    notifyListeners();
  }

  Future<void> clearKey() async {
    final active = activeProfile;
    if (active == null) return;
    await _storage.delete(key: _storageKey(active.id));
    _keys.remove(active.id);
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
    final active = activeProfile;
    if (active == null) {
      await createProfile(
        displayName: displayName,
        baseUrl: baseUrl,
        modelId: modelId,
        supportsVision: supportsVision,
        supportsJson: supportsJson,
        shareHandoutContext: shareHandoutContext,
      );
      return;
    }
    final updated = active.copyWith(
      displayName: displayName.trim().isEmpty
          ? 'Custom cloud AI'
          : displayName.trim(),
      baseUrl: baseUrl.trim().replaceAll(RegExp(r'/+$'), ''),
      modelId: modelId.trim(),
      supportsVision: supportsVision,
      supportsJson: supportsJson,
      shareHandoutContext: shareHandoutContext,
      updatedAt: DateTime.now(),
    );
    _profiles = [
      for (final profile in _profiles)
        if (profile.id == updated.id) updated else profile,
    ];
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> setShareHandoutContext(bool value) async {
    final active = activeProfile;
    if (active == null) return;
    await saveSettings(
      baseUrl: active.baseUrl,
      modelId: active.modelId,
      displayName: active.displayName,
      supportsVision: active.supportsVision,
      supportsJson: active.supportsJson,
      shareHandoutContext: value,
    );
  }

  Future<void> _persistProfiles() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _profilesPref,
      jsonEncode(_profiles.map((profile) => profile.toJson()).toList()),
    );
  }

  String _storageKey(String profileId) => 'compatible.apiKey.$profileId';
}
