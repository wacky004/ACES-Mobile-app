# Security

## Secrets

- Never commit API keys, tokens, passwords, `.env` files, keystores, or
  `key.properties`.
- DeepSeek and custom-provider keys use secure storage.
- No key is embedded in the Android app, Windows app, or repository.

## Cloud privacy

- Users choose a cloud provider explicitly.
- PDF chats send only relevant excerpts, not the whole PDF.
- The main tutor's handout sharing is opt-in.
- Provider retention and training terms are controlled by the provider.

## Local AI

- Local models and prompts remain on the device.

## Web Learning

- The app displays the live public Protocol Explorer, Electronics 101, and Learn
  Arduino sites in restricted WebViews.
- No website assets, lesson content, 3D models, or credentials are bundled.
- Navigation is limited to each resource's host; external links open in the
  system browser.
- No JavaScript bridge exposes app data, AI keys, or local files.
- Each website has its own storage and privacy behavior; CPE Reviewer data is
  separate.

## Source materials

- Handout PDFs are not committed.
- Derived handout JSON remains subject to STI/ACES licensing.
- The GitHub repository is private; do not make it public without a content
  licensing review.

## Release signing

- Current APKs use the Android debug key for sideloading.
- Generate a release keystore outside the repo and configure signing locally.
- Windows executables and installers are signed with the ACES code-signing
  certificate when `ACES_WINDOWS_PFX_PATH` and `ACES_WINDOWS_PFX_PASSWORD` are
  configured.
- Never commit the PFX, password, or exported private key.
- The updater verifies SHA-256 and, when configured, the Authenticode publisher
  thumbprint before launching the setup wizard.
