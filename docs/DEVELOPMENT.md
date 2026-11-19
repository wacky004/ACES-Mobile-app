# Development

## Environment

- Flutter 3.44.3
- Dart 3.12.2
- Android SDK 36
- minSdk 28, targetSdk 36
- Windows 10/11 x64, Visual Studio Build Tools with Desktop C++, CMake, Windows
  10 SDK, and C++/WinRT
- Inno Setup 6
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
scripts\build_release.ps1
```

The script builds arm64 and universal Android artifacts and computes SHA-256
hashes. Release files should be stored outside git. Update `docs/RELEASES.md`.

### Windows release

```powershell
scripts\build_windows_release.ps1
```

The script builds the Windows runner, signs with the ACES certificate when the
PFX environment variables are set, compiles the Inno Setup installer, and writes
the installer plus `latest.json` to `dist\windows`. See `docs/WINDOWS.md` and
`docs/UPDATES.md`.

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
- Do not commit build caches, keys, APKs, Windows installers, or source PDFs.

## Troubleshooting

- `android/local.properties` is generated locally and ignored.
- Android build caches live in `android/.gradle/` and are ignored.
- If a content script cannot find PDFs, set `SOURCE_HANDOUT_DIR`.
- If cloud AI fails, test the provider connection in its settings screen.
