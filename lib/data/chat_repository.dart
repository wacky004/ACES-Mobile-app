import 'package:sembast/sembast.dart';

import '../models/chat_session.dart';

class ChatRepository {
  ChatRepository(this._db);

  final Database _db;
  static final StoreRef<String, Map<String, Object?>> _store =
      stringMapStoreFactory.store('ai_chat_sessions');

  Future<void> save(AiChatSession session) async {
    await _store.record(session.id).put(_db, session.toJson());
  }

  Future<AiChatSession?> latestForContext(String contextKey) async {
    final records = await _store.find(
      _db,
      finder: Finder(
        filter: Filter.equals('contextKey', contextKey),
        sortOrders: [SortOrder('updatedAt', false)],
        limit: 1,
      ),
    );
    if (records.isEmpty) return null;
    return AiChatSession.fromJson(records.first.value);
  }

  Future<List<AiChatSession>> listForContext(String contextKey) async {
    final records = await _store.find(
      _db,
      finder: Finder(
        filter: Filter.equals('contextKey', contextKey),
        sortOrders: [SortOrder('updatedAt', false)],
      ),
    );
    return records
        .map((record) => AiChatSession.fromJson(record.value))
        .toList(growable: false);
  }

  Future<AiChatSession?> get(String id) async {
    final raw = await _store.record(id).get(_db);
    return raw == null ? null : AiChatSession.fromJson(raw);
  }

  Future<void> delete(String id) async {
    await _store.record(id).delete(_db);
  }

  Future<void> deleteForPdf(String pdfId) async {
    await _store.delete(
      _db,
      finder: Finder(filter: Filter.equals('pdfId', pdfId)),
    );
  }
}
