import 'package:cpe_reviewer/data/chat_repository.dart';
import 'package:cpe_reviewer/models/chat_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

AiChatSession session({
  required String id,
  required String contextKey,
  String? pdfId,
  String title = 'Chat',
  String text = 'Hello',
}) => AiChatSession(
  id: id,
  subjectId: 'it2205',
  contextKey: contextKey,
  pdfId: pdfId,
  title: title,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  messages: [
    {'isUser': true, 'text': text},
  ],
);

void main() {
  test('saves, restores, lists, and deletes chat sessions', () async {
    final db = await databaseFactoryMemory.openDatabase('chat-test.db');
    final repo = ChatRepository(db);
    await repo.save(
      session(id: 'a', contextKey: 'pdf:1', pdfId: '1', text: 'first'),
    );
    await repo.save(
      session(id: 'b', contextKey: 'pdf:1', pdfId: '1', text: 'second'),
    );
    await repo.save(session(id: 'c', contextKey: 'tutor:it2205'));

    final sessions = await repo.listForContext('pdf:1');
    expect(sessions.map((item) => item.id).toSet(), {'a', 'b'});
    expect(
      (await repo.latestForContext('pdf:1'))!.messages.single['text'],
      isNotEmpty,
    );
    expect(await repo.get('missing'), isNull);

    await repo.deleteForPdf('1');
    expect(await repo.listForContext('pdf:1'), isEmpty);
    expect((await repo.listForContext('tutor:it2205')).length, 1);

    await repo.delete('c');
    expect(await repo.listForContext('tutor:it2205'), isEmpty);
    await db.close();
  });
}
