# Changelog

All notable changes are recorded here. Release binaries are kept outside git;
see `docs/RELEASES.md`.

## 1.7.0 - 2026-11-09

### Added
- Multiple saved custom cloud profiles with per-profile secure API keys.
- Cloud profile migration from the previous single custom-provider slot.
- Local AI engine on/off switch that unloads RAM but keeps downloaded models.
- Automatic local-model unload when switching to DeepSeek or custom cloud AI.
- Prominent Active AI banner showing the current provider and model.
- Full-text handout reader split into pages and smaller parts.
- Page/part navigation, jump menu, progress, and resume position.

### Changed
- Cloud provider settings now manage a profile list instead of one slot.
- The provider picker lists saved cloud profiles for quick switching.
- The chat header shows a clear on-device/cloud status.

## 1.6.0 - 2026-11-09

### Added
- Persistent AI chat sessions for the Tutor and My PDFs chats.
- Session history, resume, new session, and delete controls.
- Automatic relevant PDF excerpts in PDF chats for local and cloud AI.
- OpenAI-compatible BYO cloud provider with secure key storage, vision/JSON
  capability switches, and optional tutor handout context.
- ACES navy/steel-blue/sky/paper/coral palette with circuit-pattern accents.
- Draft progress elapsed timer and explicit model/cloud loading phases.
- Documentation suite, agent workflow, CI, and release helper scripts.

### Changed
- Removed Prelim-Finals term chips from the Tutor module; term filtering stays
  in the Library handouts reader.
- Cloud PDF chat no longer requires re-uploading the opened PDF.
- Provider-aware chat banners and assistant provider labels.
- Draft provider selection supports local, DeepSeek, and custom cloud.
- Rebuilt the project into the ACES-Mobile-app repository.

### Fixed
- Draft generation no longer appears frozen at 0%; progress is indeterminate
  until the first batch or response arrives.
- Chat history is restored when returning to a PDF or Tutor session.
- Cloud PDF context is included automatically.

## 1.5.0

- Added Embedded Systems (IT2102) and Robot Dynamics (IT1919).
- Added 160 items per subject, including modified True/False items.
- Added full readers and full-text search for the new subjects.
- Added 40 modified True/False items to IT2205.
- Added fresh-item retake priority and provider-aware subject AI context.
- Added ACES generic branding, subject-aware AI prompts, and reader progress
  scoping.

## 1.4.0

- Added DeepSeek online AI with secure BYOK storage.
- Added photo, PDF-page, and text attachments.
- Added thinking/reasoning display, token usage, and JSON draft generation.
- Added DeepSeek model/provider picker and privacy settings.
- Verified the web build remains AI-free.

## 1.3.0

- Added the handout reader, key terms, tables, flashcards, search, and reader
  progress.
- Added reader practice quizzes and full-text chunks.
- Fixed AI model download foreground-service behavior.

## 1.2.0

- Added local AI model download fixes, multiple model choices, and model picker.

## 1.1.0

- Added on-device AI tutor and offline model manager.

## 1.0.0

- Initial 120-item IT2205 reviewer with weighted terms, practice/exam modes,
  progress, bookmarks, and retry-missed.
