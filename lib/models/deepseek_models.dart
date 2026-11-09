import 'dart:typed_data';

class DeepSeekModelSpec {
  const DeepSeekModelSpec({
    required this.id,
    required this.displayName,
    required this.description,
    required this.supportsVision,
  });

  final String id;
  final String displayName;
  final String description;
  final bool supportsVision;
}

const List<DeepSeekModelSpec> deepSeekModels = [
  DeepSeekModelSpec(
    id: 'deepseek-flash',
    displayName: 'DeepSeek Flash',
    description:
        'Fast online model. Supports photos and PDF page images. Requires internet and an API key.',
    supportsVision: true,
  ),
  DeepSeekModelSpec(
    id: 'deepseek-v4-pro',
    displayName: 'DeepSeek V4 Pro',
    description:
        'Highest-quality text answers. For images or PDF pages, the app uses Flash.',
    supportsVision: false,
  ),
];

DeepSeekModelSpec deepSeekModelById(String? id) {
  for (final model in deepSeekModels) {
    if (model.id == id) return model;
  }
  return deepSeekModels.first;
}

enum DeepSeekAttachmentKind { image, pdf, text }

class DeepSeekPageImage {
  const DeepSeekPageImage({required this.page, required this.bytes});
  final int page;
  final Uint8List bytes;
}

class DeepSeekAttachment {
  const DeepSeekAttachment({
    required this.kind,
    required this.filename,
    this.bytes,
    this.text,
    this.pageImages = const [],
    this.pageCount = 0,
    this.note = '',
    this.highDetail = false,
  });

  final DeepSeekAttachmentKind kind;
  final String filename;
  final Uint8List? bytes;
  final String? text;
  final List<DeepSeekPageImage> pageImages;
  final int pageCount;
  final String note;
  final bool highDetail;
  bool get hasImages =>
      kind == DeepSeekAttachmentKind.image || pageImages.isNotEmpty;

  int get inlineImageBytes {
    var total = bytes?.length ?? 0;
    for (final page in pageImages) {
      total += page.bytes.length;
    }
    return total;
  }

  int get textLength => text?.length ?? 0;

  String get label {
    switch (kind) {
      case DeepSeekAttachmentKind.image:
        return filename;
      case DeepSeekAttachmentKind.pdf:
        final parts = <String>['$filename · PDF'];
        if (pageCount > 0) parts.add('$pageCount pages');
        if (pageImages.isNotEmpty) {
          parts.add('${pageImages.length} page images');
        }
        return parts.join(' · ');
      case DeepSeekAttachmentKind.text:
        return '$filename · text';
    }
  }

  String get mimeType {
    final name = filename.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.gif')) return 'image/gif';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

class DeepSeekUsage {
  const DeepSeekUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    this.reasoningTokens = 0,
  });

  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final int reasoningTokens;

  Map<String, dynamic> toJson() => {
        'prompt_tokens': promptTokens,
        'completion_tokens': completionTokens,
        'total_tokens': totalTokens,
        'completion_tokens_details': {'reasoning_tokens': reasoningTokens},
      };

  factory DeepSeekUsage.fromJson(Map<String, dynamic> json) {
    final details = json['completion_tokens_details'];
    final reasoning = details is Map
        ? (details['reasoning_tokens'] as num?)?.toInt() ?? 0
        : 0;
    return DeepSeekUsage(
      promptTokens: (json['prompt_tokens'] as num?)?.toInt() ?? 0,
      completionTokens: (json['completion_tokens'] as num?)?.toInt() ?? 0,
      totalTokens: (json['total_tokens'] as num?)?.toInt() ?? 0,
      reasoningTokens: reasoning,
    );
  }
}

class DeepSeekBalance {
  const DeepSeekBalance({
    required this.isAvailable,
    required this.currency,
    required this.totalBalance,
    required this.grantedBalance,
    required this.toppedUpBalance,
  });

  final bool isAvailable;
  final String currency;
  final String totalBalance;
  final String grantedBalance;
  final String toppedUpBalance;
}

class DeepSeekChunk {
  const DeepSeekChunk({this.content, this.reasoning, this.usage});
  final String? content;
  final String? reasoning;
  final DeepSeekUsage? usage;
}

class DeepSeekException implements Exception {
  const DeepSeekException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
