# Windows updates

Windows builds use an app-driven update check plus an Inno Setup wizard. The
app never installs an update silently.

## Release repository

Update assets are published in the public repository:

```text
https://github.com/wacky004/ACES-Reviewer-Releases
```

The source repository remains private. The public repository contains only
release assets and the update manifest.

## Update manifest

Each release publishes:

```text
CPE-Reviewer-<version>-Windows-x64-Setup.exe
latest.json
```

Example `latest.json`:

```json
{
  "version": "1.8.1",
  "installer_url": "https://github.com/wacky004/ACES-Reviewer-Releases/releases/download/v1.8.1/CPE-Reviewer-1.8.1-Windows-x64-Setup.exe",
  "sha256": "<sha256>",
  "notes": "Bug fixes and desktop improvements.",
  "publisher_thumbprint": "<certificate thumbprint>",
  "mandatory": false
}
```

The app reads:

```text
https://github.com/wacky004/ACES-Reviewer-Releases/releases/latest/download/latest.json
```

The URL can be overridden at build time:

```powershell
flutter build windows --release --dart-define=UPDATE_MANIFEST_URL=https://example.com/latest.json
```

## App flow

1. The app checks after startup at most once every 24 hours.
2. The user can also check manually from Settings.
3. If a newer version exists, the app shows the version and release notes.
4. “Download and install” downloads the installer to the app-support
   directory and reports progress.
5. The app verifies SHA-256.
6. If `publisher_thumbprint` is present, the app verifies the Authenticode
   signer and publisher thumbprint.
7. The app launches the installer with `/UPDATECHECK=1`.
8. The app exits; the setup wizard updates the per-user installation.
9. The installer relaunches the app after completion.

If the user cancels the wizard, the current installation is unchanged and the
app can be reopened.

## Publishing

1. Run `scripts\build_windows_release.ps1`.
2. Sign the build with the ACES certificate.
3. Upload the setup executable and `latest.json` to a GitHub release tagged
   `v<version>` in `ACES-Reviewer-Releases`.
4. Confirm the “latest” manifest URL returns the new manifest.
5. Install an older build and test the upgrade path.

## Security

- Do not host updates in the private source repository; the app has no GitHub
  token.
- Use HTTPS for the manifest and installer.
- Keep the source certificate private; only the thumbprint is public.
- Never disable hash or signature verification for production releases.
