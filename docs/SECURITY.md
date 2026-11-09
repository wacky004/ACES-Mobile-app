# Security

## Secrets

- Never commit API keys, tokens, passwords, `.env` files, keystores, or
  `key.properties`.
- DeepSeek and custom-provider keys use secure storage.
- No key is embedded in the APK, web bundle, or repository.

## Cloud privacy

- Users choose a cloud provider explicitly.
- PDF chats send only relevant excerpts, not the whole PDF.
- The main tutor's handout sharing is opt-in.
- Provider retention and training terms are controlled by the provider.

## Local AI

- Local models and prompts remain on the device.

## Web

- The web build contains no AI providers, keys, or cloud requests.

## Source materials

- Handout PDFs are not committed.
- Derived handout JSON remains subject to STI/ACES licensing.
- The GitHub repository is private; do not make it public without a content
  licensing review.

## Release signing

- Current APKs use the Android debug key for sideloading.
- Generate a release keystore outside the repo and configure signing locally.
