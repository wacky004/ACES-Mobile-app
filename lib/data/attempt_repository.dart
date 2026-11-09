import 'package:sembast/sembast.dart';

import '../models/quiz_models.dart';

class AttemptRepository {
  AttemptRepository(this._db);

  final Database _db;
  static final StoreRef<String, Map<String, Object?>> _store =
      stringMapStoreFactory.store('attempts');

  Future<void> save(Attempt attempt) async {
    await _store.record(attempt.id).put(_db, attempt.toJson());
  }

  Future<List<Attempt>> forSubject(String subjectId, {int limit = 200}) async {
    final finder = Finder(
      filter: Filter.equals('subjectId', subjectId),
      sortOrders: [SortOrder('finishedAt', false)],
      limit: limit,
    );
    final records = await _store.find(_db, finder: finder);
    return records
        .map((record) => Attempt.fromJson(record.value))
        .toList(growable: false);
  }

  Future<void> deleteForSubject(String subjectId) async {
    final finder = Finder(filter: Filter.equals('subjectId', subjectId));
    await _store.delete(_db, finder: finder);
  }

  Future<void> deleteAll() async {
    await _store.delete(_db);
  }
}
