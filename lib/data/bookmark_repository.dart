import 'package:sembast/sembast.dart';

class BookmarkRepository {
  BookmarkRepository(this._db);

  final Database _db;
  static final StoreRef<String, Map<String, Object?>> _store =
      stringMapStoreFactory.store('bookmarks');

  String _key(String subjectId, String questionId) =>
      '$subjectId::$questionId';

  Future<bool> isBookmarked(String subjectId, String questionId) async {
    final record = await _store.record(_key(subjectId, questionId)).get(_db);
    return record != null;
  }

  Future<Set<String>> idsForSubject(String subjectId) async {
    final records = await _store.find(
      _db,
      finder: Finder(filter: Filter.equals('subjectId', subjectId)),
    );
    return records
        .map((record) => record.value['questionId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<bool> toggle(String subjectId, String questionId) async {
    final key = _key(subjectId, questionId);
    final existing = await _store.record(key).get(_db);
    if (existing != null) {
      await _store.record(key).delete(_db);
      return false;
    }
    await _store.record(key).put(_db, {
      'subjectId': subjectId,
      'questionId': questionId,
      'savedAt': DateTime.now().toIso8601String(),
    });
    return true;
  }

  Future<void> clearForSubject(String subjectId) async {
    final finder = Finder(filter: Filter.equals('subjectId', subjectId));
    await _store.delete(_db, finder: finder);
  }
}
