const String aiModelId = 'qwen2.5-3b-instruct-q4_k_m';
const String aiModelFileName = 'qwen2.5-3b-instruct-q4_k_m.gguf';
const int aiModelBytes = 2104932768;
const String aiModelDisplayName = 'Qwen2.5-3B Instruct · Q4';
const String aiModelSizeLabel = '2.1 GB';
const String aiModelLicense = 'Apache 2.0';
const int aiContextTokens = 4096;
const int aiMaxOutputTokens = 500;

/// Pinned Hugging Face revision so the downloaded file cannot change silently.
const String aiModelUrl =
    'https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/'
    '7dabda4d13d513e3e842b20f0d435c732f172cbe/'
    'qwen2.5-3b-instruct-q4_k_m.gguf';

/// Optional school-hosted mirror. Build with:
/// --dart-define=AI_MODEL_MIRROR_URL=https://your-host/qwen2.5-3b-instruct-q4_k_m.gguf
const String aiModelMirrorUrl = String.fromEnvironment(
  'AI_MODEL_MIRROR_URL',
  defaultValue: '',
);
