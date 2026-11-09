import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sembast/sembast.dart';

import '../models/subject_pack.dart';

class PackValidationException implements Exception {
  PackValidationException(this.problems);
  final List<String> problems;

  @override
  String toString() => problems.join('\n');
}

class PackRepository {
  PackRepository(this._db);

  final Database _db;
  static final StoreRef<String, Map<String, Object?>> _store =
      stringMapStoreFactory.store('packs');

  static const bundledPackAssets = [
    'assets/packs/it2205.json',
    'assets/packs/it2102.json',
    'assets/packs/it1919.json',
  ];

  Future<void> seedBundledPacks() async {
    for (final asset in bundledPackAssets) {
      await _seedBundle(asset);
    }
  }

  Future<void> seedBundledPack() => seedBundledPacks();

  Future<void> _seedBundle(String asset) async {
    final raw = await rootBundle.loadString(asset);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException(
        'The bundled subject pack $asset is not an object.',
      );
    }
    final pack = SubjectPack.fromJson(decoded);
    final problems = SubjectPack.validate(pack);
    if (problems.isNotEmpty) throw PackValidationException(problems);

    final existingRaw = await _store.record(pack.id).get(_db);
    if (existingRaw == null) {
      await _store.record(pack.id).put(_db, pack.toJson());
      return;
    }
    final existing = SubjectPack.fromJson(existingRaw);
    if (_compareVersions(pack.version, existing.version) > 0) {
      await _store.record(pack.id).put(_db, pack.toJson());
    }
  }

  Future<List<SubjectPack>> loadAll() async {
    final records = await _store.find(_db);
    final packs = records
        .map((record) => SubjectPack.fromJson(record.value))
        .toList(growable: false);
    packs.sort(
      (a, b) => a.subject.toLowerCase().compareTo(b.subject.toLowerCase()),
    );
    return packs;
  }

  Future<SubjectPack?> getById(String id) async {
    final raw = await _store.record(id).get(_db);
    return raw == null ? null : SubjectPack.fromJson(raw);
  }

  Future<void> save(SubjectPack pack) async {
    await _store.record(pack.id).put(_db, pack.toJson());
  }

  Future<SubjectPack> importBytes(Uint8List bytes) async {
    try {
      return await importJsonString(utf8.decode(bytes));
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Could not read the selected file: $error');
    }
  }

  Future<SubjectPack> importJsonString(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The file must contain a JSON object.');
    }

    late SubjectPack pack;
    if (SubjectPack.isFullPackJson(decoded)) {
      pack = SubjectPack.fromJson(decoded);
    } else if (decoded['subjectId'] is String && decoded['questions'] is List) {
      final existing = await getById(decoded['subjectId'] as String);
      if (existing == null) {
        throw FormatException(
          'No installed subject matches "${decoded['subjectId']}". '
          'Import a full pack first, or use the matching subject id.',
        );
      }
      pack = SubjectPack.mergeQuestions(existing, decoded);
    } else {
      throw const FormatException(
        'Unrecognized pack format. Use a full subject pack (with "id" and '
        '"terms") or a question merge file with "subjectId" and "questions".',
      );
    }

    final problems = SubjectPack.validate(pack);
    if (problems.isNotEmpty) throw PackValidationException(problems);
    await save(pack);
    return pack;
  }

  Future<void> delete(String id) async {
    await _store.record(id).delete(_db);
  }
}

int _compareVersions(String a, String b) {
  final left = a.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  final right = b.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  final length = left.length > right.length ? left.length : right.length;
  for (var index = 0; index < length; index++) {
    final l = index < left.length ? left[index] : 0;
    final r = index < right.length ? right[index] : 0;
    if (l != r) return l.compareTo(r);
  }
  return 0;
}
