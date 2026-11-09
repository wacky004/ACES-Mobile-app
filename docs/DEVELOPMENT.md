# Development

## Environment

- Flutter 3.44.3
- Dart 3.12.2
- Android SDK 36
- minSdk 28, targetSdk 36
- Python 3.11+

## Commands

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

## Verification

```powershell
scripts\verify.ps1
```

The script checks formatting, analysis, and tests.

## Release build

```powershell
scripts\build_release.ps1 -Version 1.6.0
```

The script builds web, arm64, and universal artifacts and computes SHA-256
hashes. Release files should be stored outside git. Update `docs/RELEASES.md`.

## Content regeneration

```powershell
$env:SOURCE_HANDOUT_DIR = "C:\path\to\ALL HANDOUT"
python tools\build_subjects.py
```

## Repository workflow

- Work in `ACES-Mobile-app`.
- One logical commit per completed task.
- Run format/analyze/test before committing.
- Update CHANGELOG and relevant docs.
- Push to `origin main`.
- Do not commit build caches, keys, APKs, web ZIPs, or source PDFs.

## Troubleshooting

- `android/local.properties` is generated locally and ignored.
- Android build caches live in `android/.gradle/` and are ignored.
- If a content script cannot find PDFs, set `SOURCE_HANDOUT_DIR`.
- If cloud AI fails, test the provider connection in its settings screen.
