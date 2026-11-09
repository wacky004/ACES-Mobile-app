import '../data/attempt_repository.dart';
import '../data/bookmark_repository.dart';
import '../data/chat_repository.dart';
import '../data/db_factory.dart';
import '../data/pack_repository.dart';
import '../data/pdf_repository.dart';
import '../data/settings_controller.dart';
import '../models/subject_pack.dart';
import 'app_session.dart';

class Bootstrap {
  const Bootstrap({
    required this.session,
    required this.settings,
    required this.pdfRepository,
    required this.chatRepository,
  });
  final AppSession session;
  final SettingsController settings;
  final PdfRepository pdfRepository;
  final ChatRepository chatRepository;
}

Future<Bootstrap> bootstrapApp() async {
  final startedAt = DateTime.now();
  final database = await openAppDatabase();
  final packRepository = PackRepository(database);
  await packRepository.seedBundledPacks();
  final packs = await packRepository.loadAll();
  if (packs.isEmpty) {
    throw StateError('No subject packs are available.');
  }
  final settings = await SettingsController.load();
  final attemptRepository = AttemptRepository(database);
  final bookmarkRepository = BookmarkRepository(database);
  final pdfRepository = PdfRepository(database);
  final chatRepository = ChatRepository(database);

  final preferred = settings.lastSubjectId;
  final initialSubject = packs.firstWhere(
    (pack) => pack.id == preferred,
    orElse: () => packs.first,
  );

  final session = AppSession(
    packRepository: packRepository,
    attemptRepository: attemptRepository,
    bookmarkRepository: bookmarkRepository,
    settings: settings,
    packs: List<SubjectPack>.of(packs),
    subject: initialSubject,
  );
  await session.initialize();

  final elapsed = DateTime.now().difference(startedAt);
  const minimumSplash = Duration(milliseconds: 1100);
  if (elapsed < minimumSplash) {
    await Future<void>.delayed(minimumSplash - elapsed);
  }
  return Bootstrap(
    session: session,
    settings: settings,
    pdfRepository: pdfRepository,
    chatRepository: chatRepository,
  );
}
