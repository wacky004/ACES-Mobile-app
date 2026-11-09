# ACES Mobile App - CPE Reviewer

A Flutter reviewer for Computer Engineering students at STI Ortigas-Cainta.

## Current subjects

| Subject | Code | Handouts | Items |
|---|---|---:|---:|
| Computer Engineering Laws and Discipline | IT2205 | 8 | 160 |
| Embedded Systems | IT2102 | 5 | 160 |
| Robot Dynamics | IT1919 | 6 | 160 |

Every term (Prelim, Midterm, Pre-Finals, Finals) has 40 items:
30 multiple-choice questions and 10 modified True/False questions.

## Features

- Weighted term quizzes with configurable grading weights.
- Practice and exam modes, timer, flags, bookmarks, and retry-missed.
- Fresh-item priority on retakes and shuffled multiple-choice options.
- Modified True/False questions with an underlined term and a correction.
- Handout reader with page/part full text, search, sections, key terms, tables, and flashcards.
- Offline AI with downloadable Qwen/Gemma models.
- DeepSeek online AI with secure BYOK storage.
- Multiple saved OpenAI-compatible cloud profiles for free tiers or self-hosted endpoints.
- Local AI engine on/off switch and clear active-model indicator.
- Automatic relevant PDF excerpts in PDF chats for local and cloud AI.
- Persistent AI chat sessions with new/history/resume/delete.
- PDF import, PDF chat, and draft-quiz generation.
- AI-free web build; Android-only AI features.

## Requirements

- Flutter 3.44.3 / Dart 3.12.2
- Android SDK 36, minSdk 28
- Python 3.11+ for content generation scripts
- Internet only for model downloads and cloud AI

## Quick start

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

## Build

```powershell
flutter build web --release
flutter build apk --release --target-platform android-arm64
flutter build apk --release
```

Release APKs, web ZIPs, source PDFs, and hashes are kept outside git. See
`docs/RELEASES.md` and `docs/DEVELOPMENT.md`.

## Repository layout

```text
android/            Android shell and manifest
assets/handouts/    Reader packs and full-text chunks
assets/packs/       Subject question packs
lib/                Flutter application
test/               Unit and widget tests
tools/              PDF extraction, content, and validation scripts
docs/               Project documentation
scripts/            Verification and release helpers
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Features](docs/FEATURES.md)
- [AI and privacy](docs/AI.md)
- [Content pipeline](docs/CONTENT.md)
- [Development](docs/DEVELOPMENT.md)
- [Security](docs/SECURITY.md)
- [Releases](docs/RELEASES.md)
- [Decisions](docs/DECISIONS.md)
- [Palette](docs/PALETTE.md)
- [Roadmap](docs/ROADMAP.md)
- [Agent instructions](AGENTS.md)

## Source materials

The original handout PDFs stay outside this repository. Only derived JSON,
scripts, and documentation are committed. Handout content is property of STI
and is intended for ACES classroom use.

## Release signing

Current release APKs are debug-signed for sideloading. Create and protect a
release keystore before publishing to Google Play.
