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
- Windows code-signing PFX files and certificate passwords
- `build/`, `.dart_tool/`, `android/.gradle/`, caches
- APK/AAB files and Windows installer binaries
- Original handout PDFs
- Personal or private student data

## AI rules

- Local AI and cloud providers are supported on Android and Windows.
- The web target is removed from `main`; do not reintroduce it without approval.
- API keys live in secure storage, never in source or SharedPreferences.
- PDF chats use relevant excerpts from the opened PDF automatically.
- The main tutor handout-context switch is opt-in.
- Never reuse OpenCode credentials or claim OpenCode is a public inference API.
- The optional custom provider is BYO: base URL, model ID, and the user's key.
- Preserve multiple saved cloud profiles and their profile-specific secure keys.
- Turning Local AI off unloads RAM only; never delete downloaded model files
  unless the user explicitly deletes the model.
- Selecting cloud AI should unload the local engine automatically.
- Keep the full-text reader paginated by page/long-page parts.
- Protocol Explorer, Electronics 101, and Learn Arduino are remote WebViews. Do
  not bundle or copy their website assets, 3D models, lesson text, or branding
  without written permission from the author.
- Keep each Web Learning navigation restricted to its resource host and keep
  external links in the system browser.

## Content rules

- Source handouts are external. Set `SOURCE_HANDOUT_DIR` if they move.
- Run `python tools/build_subjects.py` to regenerate derived packs and readers.
- Validate all question IDs, answer indexes, source pages, and T/F corrections.
- Keep the STI/ACES attribution and licensing notes.

## Release process

1. Bump `pubspec.yaml` version and the Settings version label.
2. Run `scripts/verify.ps1`.
3. Run `scripts/build_release.ps1`.
4. Run `scripts/build_windows_release.ps1`.
5. Record artifact filenames, sizes, and SHA-256 hashes in `docs/RELEASES.md`.
6. Publish the Windows installer and `latest.json` to the public release repo.
7. Do not commit release binaries.
