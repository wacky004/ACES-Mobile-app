# Web Learning

CPE Reviewer links to interactive learning sites by
[Dilum Sanjaya](https://x.com/DilumSanjaya) through in-app WebViews.

| Resource | URL | Content |
|---|---|---|
| Protocol Explorer | https://protocol-explorer-alpha.vercel.app/ | 39 networking lessons, 20 languages |
| Electronics 101 | https://electronics-101-six.vercel.app/ | 48 electronics lessons on a 3D workbench |
| Learn Arduino | https://learn-arduino-red.vercel.app/ | 16 Arduino lessons, 3D board and simulator |

Electronics 101 opens the course home, so all lessons, including the
Hall-effect sensor lesson, are reachable.

## Entry points

- **Home:** Web Learning card section.
- **Library:** Web tab with all three resources.
- Author attribution is visible in the app and on each screen.

## Integration

The app loads the live sites in Android WebView and Windows WebView2 through
`webview_all`. It does not bundle or copy the sites’ HTML, JavaScript, CSS, 3D
models, fonts, lesson text, illustrations, or branding.

Each resource has:

- Its own allowed host.
- Loading progress, retry, and offline handling.
- Web history controls and reload.
- An “Open in browser” fallback.
- External links opened in the system browser.
- No JavaScript bridge to app data.

## 3D support

Electronics 101 and Learn Arduino use WebGL/3D content:

- Android WebView requires hardware acceleration; the app manifest enables it.
- Windows uses Microsoft Edge WebView2.
- Windows 11 and current Windows 10 include the WebView2 Runtime. If it is
  missing, the screen offers an install link.
- Mouse, keyboard, and touch controls are handled by the websites.
- If a 3D page fails or performs poorly, use “Open in browser.”

## Data and privacy

Each website stores its own progress, theme, and language in WebView
`localStorage`. This is separate from CPE Reviewer quiz progress, bookmarks, AI
profiles, and cloud keys. All three resources require internet.

## URL overrides

Build-time overrides are available:

```powershell
flutter build windows --release `
  --dart-define=PROTOCOL_EXPLORER_URL=https://example.com/ `
  --dart-define=ELECTRONICS_101_URL=https://example.com/ `
  --dart-define=LEARN_ARDUINO_URL=https://example.com/
```

## Licensing note

No visible redistribution license or public source repository was found for
these sites. The app only displays the live public sites. Do not bundle or copy
their assets without written permission from the author. Offline support would
require that permission and a separate asset-packaging design.
