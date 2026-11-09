# AI and privacy

## Local AI

- Downloadable Qwen2.5 0.5B/1.5B/3B, Qwen3-4B, and Gemma 3 1B/4B models.
- Models are downloaded directly to the phone and loaded locally.
- No prompt leaves the device for local inference.

## DeepSeek

- BYOK: the user pastes their own DeepSeek API key.
- Key storage: `flutter_secure_storage`.
- Endpoint: `https://api.deepseek.com`.
- Supports text, images, PDF page images, thinking mode, usage statistics, and
  JSON draft generation.
- Model choices: `deepseek-flash` and `deepseek-v4-pro`.
- PDF chats automatically send relevant excerpts from the opened PDF.
- The main tutor's handout sharing switch defaults to off.

## OpenAI-compatible provider

- User supplies base URL, model ID, API key, and capability switches.
- Works with free-tier or self-hosted OpenAI-compatible endpoints.
- No key is bundled.
- PDF chats send relevant PDF excerpts automatically.
- The app cannot reuse OpenCode credentials, OpenCode Go access, GitHub Copilot
  OAuth, or any internal OpenCode model access.

## Privacy rules

- API keys are never logged or committed.
- Cloud prompts may include the question, optional attachments, and enabled
  context excerpts.
- Local AI keeps content on-device.
- The web build has no AI.

## Known limitations

- Free-tier rate limits are controlled by the provider.
- Text-only custom models cannot accept image attachments or scanned PDF pages
  as images.
- Cloud providers may have their own retention and training policies.
