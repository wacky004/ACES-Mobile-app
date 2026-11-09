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
- Multiple cloud profiles can be saved. Each profile keeps its own name,
  endpoint, model, secure API key, and capability switches.
- Select the active profile from cloud settings or the provider picker.
- PDF chats send relevant PDF excerpts automatically.
- The app cannot reuse OpenCode credentials, OpenCode Go access, GitHub Copilot
  OAuth, or any internal OpenCode model access.

## Local AI engine

- The local AI engine can be turned off without deleting downloaded model files.
- Turning it off unloads the model from memory.
- Selecting a cloud provider automatically unloads the local model to free RAM.
- Turning it back on makes local models available again; loading happens lazily.
- The chat header shows the active provider/model and local engine status.

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
