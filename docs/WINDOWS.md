# Windows desktop

CPE Reviewer supports Windows 10/11 x64 through the Flutter Windows runner.
Android remains supported; web is no longer a supported target.

## Build prerequisites

- Windows 10/11 x64
- Flutter 3.44.3 / Dart 3.12.2
- Visual Studio Build Tools 2022 with:
  - Desktop development with C++
  - MSVC x64/x86 build tools
  - C++ CMake tools for Windows
  - Windows 10/11 SDK
  - C++ ATL (required by `flutter_secure_storage`)
  - C++/WinRT headers
- Inno Setup 6
- Windows Developer Mode enabled (required by `pdfrx`)

Verify with:

```powershell
flutter doctor -v
flutter build windows --release
```

## Windows features

- Shared quizzes, reader, progress, PDF library, AI tutor, cloud profiles, and
  chat history.
- Windows-native OCR for scanned PDFs using `Windows.Media.Ocr`.
- Adaptive `NavigationRail` layout above 900 px.
- Minimum window size of 1024x720.
- Single-instance behavior: opening a second copy focuses the first window.
- Web Learning through Microsoft Edge WebView2: Protocol Explorer, Electronics
  101, and Learn Arduino.
- User data is stored under the Windows app-support directory, outside the
  installation directory.

Web Learning requires the Microsoft Edge WebView2 Runtime. It is included with
Windows 11 and current Windows 10. If it is missing, the screen provides an
install link. Electronics 101 and Learn Arduino also require WebGL.

## Build the installer

```powershell
scripts\build_windows_release.ps1
```

The script:

1. Builds `build\windows\x64\runner\Release`.
2. Signs `cpe_reviewer.exe` when `ACES_WINDOWS_PFX_PATH` and
   `ACES_WINDOWS_PFX_PASSWORD` are set.
3. Compiles `installer\windows\aces_reviewer.iss` with Inno Setup.
4. Signs the setup executable when signing is enabled.
5. Writes `dist\windows\CPE-Reviewer-<version>-Windows-x64-Setup.exe` and
   `dist\windows\latest.json`.
6. Prints the installer size and SHA-256.

Unsigned builds are allowed for local testing, but they show an unknown
publisher warning on other PCs.

## Installer behavior

- Per-user installation under `%LOCALAPPDATA%\Programs\CPE Reviewer`.
- No administrator prompt.
- Start menu shortcut; optional desktop shortcut.
- Uninstaller included.
- Updates run the same installer with `/UPDATECHECK=1`, preserving user data.
- The installer does not include source PDFs or downloaded AI models.

## Data locations

- Database, chats, PDF metadata, and settings: Windows app-support directory.
- AI models: app-support directory under `ai_models`.
- Downloads: app-support directory under `updates`.
- Application files: `%LOCALAPPDATA%\Programs\CPE Reviewer`.

Android data is not migrated automatically. Windows starts with a fresh local
database.

## Signing

Set the PFX path and password in the local environment, or in GitHub Actions
secrets:

```powershell
$env:ACES_WINDOWS_PFX_PATH = "C:\secure\aces.pfx"
$env:ACES_WINDOWS_PFX_PASSWORD = "..."
```

Never commit the PFX or password. The public update manifest includes the
publisher thumbprint so the app can reject an installer signed by another
certificate.

## Known limitations

- Windows ARM64 is not built yet.
- Windows OCR depends on installed Windows language OCR resources.
- Web Learning requires internet and WebView2; it is not available offline.
- Electronics 101 and Learn Arduino are 3D/WebGL sites and may need a browser
  fallback on very low-end hardware.
- Local AI is x64 CPU/Vulkan only; unsupported GPUs fall back to CPU.
- The installer is unsigned when the certificate environment variables are not
  set.
