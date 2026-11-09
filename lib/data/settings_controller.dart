import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subject_pack.dart';

class SettingsController extends ChangeNotifier {
  SettingsController._(this._prefs);

  final SharedPreferences _prefs;

  static const _themeKey = 'settings.themeMode';
  static const _tutorKey = 'settings.tutorEnabled';
  static const _lastSubjectKey = 'settings.lastSubjectId';
  static const _weightsKey = 'settings.weights';

  late ThemeMode _themeMode;
  late bool _tutorEnabled;
  String? _lastSubjectId;
  Map<String, Map<String, int>> _weights = {};

  ThemeMode get themeMode => _themeMode;
  bool get tutorEnabled => _tutorEnabled;
  String? get lastSubjectId => _lastSubjectId;

  static Future<SettingsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = SettingsController._(prefs);
    controller._themeMode = _parseThemeMode(prefs.getString(_themeKey));
    controller._tutorEnabled = prefs.getBool(_tutorKey) ?? true;
    controller._lastSubjectId = prefs.getString(_lastSubjectKey);
    final rawWeights = prefs.getString(_weightsKey);
    if (rawWeights != null) {
      try {
        final decoded = jsonDecode(rawWeights);
        if (decoded is Map) {
          controller._weights = decoded.map(
            (key, value) => MapEntry(
              key.toString(),
              (value as Map).map(
                (termId, weight) => MapEntry(
                  termId.toString(),
                  (weight as num).toInt(),
                ),
              ),
            ),
          );
        }
      } catch (_) {
        controller._weights = {};
      }
    }
    return controller;
  }

  Map<String, int> weightsFor(SubjectPack pack) {
    final saved = _weights[pack.id] ?? const <String, int>{};
    final result = <String, int>{};
    for (final term in pack.terms) {
      result[term.id] = saved[term.id] ?? term.defaultWeight;
    }
    return result;
  }

  Future<void> setWeight(SubjectPack pack, String termId, int value) async {
    final current = weightsFor(pack);
    current[termId] = value.clamp(0, 100);
    _weights[pack.id] = current;
    await _persistWeights();
    notifyListeners();
  }

  Future<void> resetWeights(SubjectPack pack) async {
    _weights.remove(pack.id);
    await _persistWeights();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_themeKey, mode.name);
    notifyListeners();
  }

  Future<void> setTutorEnabled(bool enabled) async {
    _tutorEnabled = enabled;
    await _prefs.setBool(_tutorKey, enabled);
    notifyListeners();
  }

  Future<void> setLastSubject(String id) async {
    _lastSubjectId = id;
    await _prefs.setString(_lastSubjectKey, id);
  }

  Future<void> resetAll() async {
    _weights = {};
    _themeMode = ThemeMode.system;
    _tutorEnabled = true;
    _lastSubjectId = null;
    await _prefs.remove(_weightsKey);
    await _prefs.remove(_themeKey);
    await _prefs.remove(_tutorKey);
    await _prefs.remove(_lastSubjectKey);
    notifyListeners();
  }

  Future<void> _persistWeights() async {
    await _prefs.setString(_weightsKey, jsonEncode(_weights));
  }

  static ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
