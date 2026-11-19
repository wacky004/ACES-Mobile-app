# Roadmap

## Completed in 1.10.0

- Shared Web Learning section on Home.
- Web tab in Library.
- Added Electronics 101: 48 lessons on a 3D electronics workbench.
- Added Learn Arduino: 16 lessons with a 3D board and simulator.
- Reusable WebView resource screen for all three sites.
- 3D/WebGL validation on Windows WebView2.
- No website assets copied; online-only integration.

## Completed in 1.9.0

- Home and Library entry points for Protocol Explorer.
- In-app Android and Windows WebView with 39 networking lessons.
- Web history, reload, external browser fallback, and attribution.
- No website assets copied; online-only integration.

## Completed in 1.8.0

- Windows desktop target with adaptive navigation and window sizing.
- Windows-native OCR for scanned PDFs.
- Single-instance handling and Windows app-support data paths.
- Per-user Inno Setup installer.
- Signed installer and Authenticode update verification.
- Public release feed and in-app update wizard launch.
- Removed the web target from `main`.

## Completed in 1.7.0

- Multiple saved custom cloud profiles with per-profile secure keys.
- Local AI engine on/off with automatic unload on cloud.
- Prominent active provider/model banner.
- Reader full-text pages/parts with navigation and resume.
- Cloud profile migration from the previous single slot.

## Completed in this repository import

- Import current CPE Reviewer source into ACES-Mobile-app.
- Add documentation, agent workflow, CI, verification, and release scripts.
- Add persistent AI chat sessions.
- Add automatic PDF excerpts for cloud AI.
- Remove Tutor term chips.
- Add draft progress phases and indeterminate progress.
- Add ACES palette and circuit-pattern appearance.
- Add OpenAI-compatible BYO provider for free-tier/custom cloud AI.

## Next candidates

- Windows clean-VM install and update validation.
- Request offline/redistribution permission for the Web Learning sites if
  offline lessons are desired.
- Validate all three Web Learning sites on a physical Android device.
- Real-device validation of local AI model loading and draft generation.
- Improve generated question quality for the one-page Robot Finals handout.
- Add question-type filters in quiz setup.
- Add a release keystore and Play Store/App Bundle pipeline.
- Optional: per-subject chat export and backup.
- Optional: OpenAI-compatible streaming fallback for non-SSE endpoints.
