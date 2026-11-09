# Agent instructions

## Repository

- Work in this repository: `ACES-Mobile-app`.
- The previous `CPE APP REVIWER\cpe_reviewer` folder is a backup, not the source of truth.
- Remote: `https://github.com/wacky004/ACES-Mobile-app.git`
- Branch: `main`

## Required workflow

After every completed task:

1. Run `dart format` on changed Dart files.
2. Run `flutter analyze`.
3. Run `flutter test`.
4. Update `CHANGELOG.md` and any affected docs.
5. Check `git status` and `git diff`.
6. Commit only the intended files with a concise conventional message.
7. Push to `origin main`.
8. Confirm the working tree is clean.

If a push fails because credentials are unavailable, stop and report the exact
command needed. Never force-push.

## Commit style

- `feat: ...`
- `fix: ...`
- `docs: ...`
- `style: ...`
- `chore: ...`
- `test: ...`

## Never commit

- API keys, tokens, passwords, `.env` files
- Android keystores, `key.properties`, `local.properties`
- `build/`, `.dart_tool/`, `android/.gradle/`, caches
- APK/AAB files, web ZIPs
- Original handout PDFs
- Personal or private student data

## AI rules

- Local AI and cloud providers are Android-only. Keep the web build AI-free.
- API keys live in secure storage, never in source or SharedPreferences.
- PDF chats use relevant excerpts from the opened PDF automatically.
- The main tutor handout-context switch is opt-in.
- Never reuse OpenCode credentials or claim OpenCode is a public inference API.
- The optional custom provider is BYO: base URL, model ID, and the user's key.

## Content rules

- Source handouts are external. Set `SOURCE_HANDOUT_DIR` if they move.
- Run `python tools/build_subjects.py` to regenerate derived packs and readers.
- Validate all question IDs, answer indexes, source pages, and T/F corrections.
- Keep the STI/ACES attribution and licensing notes.

## Release process

1. Bump `pubspec.yaml` version and the Settings version label.
2. Run `scripts/verify.ps1`.
3. Run `scripts/build_release.ps1`.
4. Record artifact filenames, sizes, and SHA-256 hashes in `docs/RELEASES.md`.
5. Do not commit release binaries.
