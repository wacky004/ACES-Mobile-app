# Architecture

## Layers

- `lib/models/` - domain models for subjects, quizzes, attempts, PDFs, AI messages,
  chat sessions, readers, and DeepSeek-compatible response data.
- `lib/data/` - Sembast repositories and persistent controllers.
- `lib/services/` - quiz generation, local AI, cloud AI, PDF import, OCR, RAG,
  updates, and attachment preparation.
- `lib/state/` - app bootstrap and session state.
- `lib/screens/` and `lib/features/` - UI screens and feature modules.

## Storage

Android stores the Sembast database in the application documents directory.
Windows stores it in the application support directory, outside the install
directory. Downloaded AI models and update installers also live in the Windows
application support directory.

Sembast stores:

- subject packs
- attempts
- bookmarks
- imported PDFs
- generated draft sets
- AI chat sessions

SharedPreferences stores lightweight settings, subject selection, cloud-profile
metadata, and the local AI engine toggle. API keys are stored with
`flutter_secure_storage`, never in Sembast or preferences. Each custom cloud
profile has its own secure key entry.

## Subject packs

`assets/packs/*.json` contain subject metadata, terms, handouts, and questions.
Questions are either `multipleChoice` or `modifiedTrueFalse`.

- Multiple-choice: exactly four unique options and one answer index.
- Modified T/F: exactly `True`/`False`, an underlined term that appears in the
  stem, and a correction when the statement is false.

## Quiz flow

`QuizService` allocates items across selected terms using configured weights,
prioritizes unseen questions from attempt history, then least-recently-seen
questions. It shuffles questions and multiple-choice options; T/F keeps
True-then-False order.

`QuizScreen` records selected answers and creates an `Attempt`; `ResultsScreen`
shows scoring, term breakdown, review, corrections, and tutor actions.

## Readers

`assets/handouts/*_reader.json` provide curated sections, key terms, and tables.
`assets/handouts/*.json` provide full-text chunks. `HandoutReaderRepository`
loads these per subject; `ReaderProgressController` tracks read handouts, known
terms, font size, last handout per subject, and the last full-text part.
Full text is shown one page/part at a time; long pages are split into smaller
reading sections.

## PDFs

`PdfImportService` extracts text and uses an `OcrService` for scanned pages.
Android uses Google ML Kit; Windows uses a native `Windows.Media.Ocr` method
channel in the Windows runner. `PdfRepository` stores PDFs and drafts. In a PDF
chat, `AiController` builds a RAG index from the PDF chunks and sends relevant
excerpts automatically for both local and cloud AI.

## AI

`AiController` owns messages, provider selection, attachments, sessions, and
draft generation.

- Local: `AiService` (flutter_edge_ai/llama.cpp) runs downloaded GGUF models.
- DeepSeek: `DeepSeekService` streams from `https://api.deepseek.com`.
- Custom: `OpenAiCompatibleService` streams from the selected user-supplied
  OpenAI-compatible cloud profile.
- Cloud selection automatically unloads the local engine; the local engine can
  also be switched off explicitly without deleting model files.
- Windows uses the same llama.cpp-backed local AI stack.

## Web Learning

`lib/features/web_learning/` contains the reusable remote WebView screen, the
three resource definitions, and the Home/Library entry widgets. The app loads
the live Protocol Explorer, Electronics 101, and Learn Arduino sites through
`webview_all` (Android WebView / Windows WebView2).

Each resource restricts navigation to its own host. No website assets are
bundled, external links use the system browser, and there is no JavaScript
bridge to app data. Site progress and language live in each WebView's
`localStorage` and do not sync with CPE Reviewer data.

## Windows shell

- `windows/` hosts the Flutter Windows runner.
- `ocr_channel.cpp` exposes `Windows.Media.Ocr` to Dart.
- `main.dart` configures the minimum window size and single-instance behavior.
- `MainShell` switches between a bottom navigation bar and a `NavigationRail`
  at the desktop breakpoint.
- `UpdateService` checks the public release manifest, downloads and verifies the
  installer, then opens the Inno Setup wizard with `/UPDATECHECK=1`.

## Chat sessions

`ChatRepository` stores sessions keyed by context:

- `tutor:<subjectId>`
- `pdf:<pdfId>`

Messages contain text, citations, reasoning, usage, attachment labels, and
provider labels. Raw image/PDF bytes are not persisted. The latest session is
restored automatically; users can start, resume, or delete sessions.
