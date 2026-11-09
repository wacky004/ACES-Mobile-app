import 'package:flutter_edge_ai/flutter_edge_ai.dart';

const String aiModelMirrorBaseUrl = String.fromEnvironment(
  'AI_MODEL_MIRROR_BASE_URL',
  defaultValue: '',
);

class AiModelSpec {
  const AiModelSpec({
    required this.id,
    required this.displayName,
    required this.filename,
    required this.url,
    required this.sizeBytes,
    required this.sizeLabel,
    required this.sha256,
    required this.modelType,
    required this.license,
    required this.ramGuide,
    required this.tag,
    required this.description,
    required this.minRamGb,
    this.recommended = false,
  });

  final String id;
  final String displayName;
  final String filename;
  final String url;
  final int sizeBytes;
  final String sizeLabel;
  final String sha256;
  final ModelType modelType;
  final String license;
  final String ramGuide;
  final String tag;
  final String description;
  final int minRamGb;
  final bool recommended;

  String get registryName =>
      filename.toLowerCase().endsWith('.gguf')
          ? filename.substring(0, filename.length - 5)
          : filename;

  String? get mirrorUrl => aiModelMirrorBaseUrl.isEmpty
      ? null
      : '${aiModelMirrorBaseUrl.replaceAll(RegExp(r'/+$'), '')}/$filename';
}

final List<AiModelSpec> aiModelCatalog = [
  AiModelSpec(
    id: 'qwen25_3b',
    displayName: 'Qwen2.5 · 3B',
    filename: 'qwen2.5-3b-instruct-q4_k_m.gguf',
    url: 'https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/'
        '7dabda4d13d513e3e842b20f0d435c732f172cbe/'
        'qwen2.5-3b-instruct-q4_k_m.gguf',
    sizeBytes: 2104932768,
    sizeLabel: '2.1 GB',
    sha256:
        '626b4a6678b86442240e33df819e00132d3ba7dddfe1cdc4fbb18e0a9615c62d',
    modelType: ModelType.qwen,
    license: 'Apache 2.0',
    ramGuide: '6–8 GB RAM',
    tag: 'RECOMMENDED',
    description:
        'Best balance for 8 GB phones. Strong English answers, good speed.',
    minRamGb: 6,
    recommended: true,
  ),
  AiModelSpec(
    id: 'qwen25_1p5b',
    displayName: 'Qwen2.5 · 1.5B',
    filename: 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
    url: 'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/'
        '91cad51170dc346986eccefdc2dd33a9da36ead9/'
        'qwen2.5-1.5b-instruct-q4_k_m.gguf',
    sizeBytes: 1117320736,
    sizeLabel: '1.1 GB',
    sha256:
        '6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e',
    modelType: ModelType.qwen,
    license: 'Apache 2.0',
    ramGuide: '4–6 GB RAM',
    tag: 'FAST',
    description:
        'Faster and lighter. Good for 4–6 GB phones and quicker answers.',
    minRamGb: 4,
  ),
  AiModelSpec(
    id: 'qwen25_0p5b',
    displayName: 'Qwen2.5 · 0.5B',
    filename: 'qwen2.5-0.5b-instruct-q4_k_m.gguf',
    url: 'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/'
        '9217f5db79a29953eb74d5343926648285ec7e67/'
        'qwen2.5-0.5b-instruct-q4_k_m.gguf',
    sizeBytes: 491400032,
    sizeLabel: '491 MB',
    sha256:
        '74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db',
    modelType: ModelType.qwen,
    license: 'Apache 2.0',
    ramGuide: '3–4 GB RAM',
    tag: 'LOW-END',
    description:
        'Smallest option. Use for low-RAM phones or quick draft questions.',
    minRamGb: 3,
  ),
  AiModelSpec(
    id: 'qwen3_4b',
    displayName: 'Qwen3 · 4B',
    filename: 'Qwen3-4B-Instruct-2507-Q4_K_M.gguf',
    url: 'https://huggingface.co/unsloth/Qwen3-4B-Instruct-2507-GGUF/resolve/'
        'a06e946bb6b655725eafa393f4a9745d460374c9/'
        'Qwen3-4B-Instruct-2507-Q4_K_M.gguf',
    sizeBytes: 2497281120,
    sizeLabel: '2.5 GB',
    sha256:
        '3605803b982cb64aead44f6c1b2ae36e3acdb41d8e46c8a94c6533bc4c67e597',
    modelType: ModelType.qwen,
    license: 'Apache 2.0',
    ramGuide: '8 GB+ RAM',
    tag: 'QUALITY',
    description:
        'Highest-quality Qwen option. Slower and closer to the 8 GB memory limit.',
    minRamGb: 8,
  ),
  AiModelSpec(
    id: 'gemma3_1b',
    displayName: 'Gemma 3 · 1B',
    filename: 'gemma-3-1b-it-Q4_K_M.gguf',
    url: 'https://huggingface.co/unsloth/gemma-3-1b-it-GGUF/resolve/'
        'f0b45be0aac41bd6a100a4b5734cad5f67255bfb/'
        'gemma-3-1b-it-Q4_K_M.gguf',
    sizeBytes: 806058272,
    sizeLabel: '806 MB',
    sha256:
        '8270790f3ab69fdfe860b7b64008d9a19986d8df7e407bb018184caa08798ebd',
    modelType: ModelType.gemmaIt,
    license: 'Gemma Terms of Use',
    ramGuide: '4–6 GB RAM',
    tag: 'GEMMA',
    description:
        'Google Gemma 3 1B. Compact, multilingual, and good on mid-range phones.',
    minRamGb: 4,
  ),
  AiModelSpec(
    id: 'gemma3_4b',
    displayName: 'Gemma 3 · 4B',
    filename: 'gemma-3-4b-it-Q4_K_M.gguf',
    url: 'https://huggingface.co/unsloth/gemma-3-4b-it-GGUF/resolve/'
        '5a3566e716d80f709ed7b79817eaf7733d2a1fce/'
        'gemma-3-4b-it-Q4_K_M.gguf',
    sizeBytes: 2489894016,
    sizeLabel: '2.5 GB',
    sha256:
        '04a43a22e8d2003deda5acc262f68ec1005fa76c735a9962a8c77042a74a7d19',
    modelType: ModelType.gemmaIt,
    license: 'Gemma Terms of Use',
    ramGuide: '8 GB+ RAM',
    tag: 'GEMMA',
    description:
        'Google Gemma 3 4B. Stronger reasoning and multilingual answers; slower on 8 GB.',
    minRamGb: 8,
  ),
];

AiModelSpec? aiModelById(String? id) {
  if (id == null) return null;
  for (final model in aiModelCatalog) {
    if (model.id == id) return model;
  }
  return null;
}

AiModelSpec get defaultAiModel =>
    aiModelCatalog.firstWhere((model) => model.recommended,
        orElse: () => aiModelCatalog.first);
