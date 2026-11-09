import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReaderProgressController extends ChangeNotifier {
  static const _readKey = 'reader.readHandouts';
  static const _lastHandoutKey = 'reader.lastHandout';
  static const _lastSectionKey = 'reader.lastSection';
  static const _fontSizeKey = 'reader.fontSize';
  static const _knownTermsKey = 'reader.knownTerms';

  SharedPreferences? _prefs;
  Set<String> _readHandouts = {};
  Set<String> _knownTerms = {};
  String? _lastHandoutId;
  String? _lastSectionId;
  double _fontSize = 16;
  bool _loaded = false;

  bool get loaded => _loaded;
  Set<String> get readHandouts => Set.unmodifiable(_readHandouts);
  Set<String> get knownTerms => Set.unmodifiable(_knownTerms);
  String? get lastHandoutId => _lastHandoutId;
  String? get lastSectionId => _lastSectionId;

  String? lastHandoutFor(String subjectId) {
    final scoped = _prefs?.getString('$_lastHandoutKey.$subjectId');
    if (scoped != null) return scoped;
    if (subjectId == 'it2205') return _lastHandoutId;
    return null;
  }

  int textPartFor(String subjectId, String handoutId) {
    return _prefs?.getInt('reader.textPart.$subjectId.$handoutId') ?? 0;
  }

  Future<void> saveTextPart(
    String subjectId,
    String handoutId,
    int index,
  ) async {
    await _prefs?.setInt('reader.textPart.$subjectId.$handoutId', index);
  }

  String? lastSectionFor(String subjectId) {
    final scoped = _prefs?.getString('$_lastSectionKey.$subjectId');
    if (scoped != null) return scoped;
    if (subjectId == 'it2205') return _lastSectionId;
    return null;
  }

  double get fontSize => _fontSize;
  int get readCount => _readHandouts.length;

  bool isRead(String handoutId) => _readHandouts.contains(handoutId);

  bool isTermKnown(String termId) => _knownTerms.contains(termId);

  Future<void> load() async {
    if (_loaded) return;
    _prefs = await SharedPreferences.getInstance();
    _readHandouts = (_prefs!.getStringList(_readKey) ?? const []).toSet();
    _knownTerms = (_prefs!.getStringList(_knownTermsKey) ?? const []).toSet();
    _lastHandoutId = _prefs!.getString(_lastHandoutKey);
    _lastSectionId = _prefs!.getString(_lastSectionKey);
    _fontSize = _prefs!.getDouble(_fontSizeKey) ?? 16;
    _loaded = true;
    notifyListeners();
  }

  Future<void> markRead(String handoutId, bool read) async {
    if (read) {
      _readHandouts.add(handoutId);
    } else {
      _readHandouts.remove(handoutId);
    }
    await _prefs?.setStringList(_readKey, _readHandouts.toList());
    notifyListeners();
  }

  Future<void> saveLast(
    String subjectId,
    String handoutId,
    String? sectionId,
  ) async {
    if (subjectId == 'it2205') {
      _lastHandoutId = handoutId;
      _lastSectionId = sectionId;
      await _prefs?.setString(_lastHandoutKey, handoutId);
    }
    await _prefs?.setString('$_lastHandoutKey.$subjectId', handoutId);
    if (sectionId == null) {
      if (subjectId == 'it2205') {
        await _prefs?.remove(_lastSectionKey);
      }
      await _prefs?.remove('$_lastSectionKey.$subjectId');
    } else {
      if (subjectId == 'it2205') {
        await _prefs?.setString(_lastSectionKey, sectionId);
      }
      await _prefs?.setString('$_lastSectionKey.$subjectId', sectionId);
    }
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(14, 22);
    await _prefs?.setDouble(_fontSizeKey, _fontSize);
    notifyListeners();
  }

  Future<void> setTermKnown(String termId, bool known) async {
    if (known) {
      _knownTerms.add(termId);
    } else {
      _knownTerms.remove(termId);
    }
    await _prefs?.setStringList(_knownTermsKey, _knownTerms.toList());
    notifyListeners();
  }
}
