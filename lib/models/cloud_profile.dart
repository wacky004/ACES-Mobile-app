class CloudProfile {
  const CloudProfile({
    required this.id,
    required this.displayName,
    required this.baseUrl,
    required this.modelId,
    required this.supportsVision,
    required this.supportsJson,
    required this.shareHandoutContext,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String displayName;
  final String baseUrl;
  final String modelId;
  final bool supportsVision;
  final bool supportsJson;
  final bool shareHandoutContext;
  final DateTime createdAt;
  final DateTime updatedAt;

  CloudProfile copyWith({
    String? displayName,
    String? baseUrl,
    String? modelId,
    bool? supportsVision,
    bool? supportsJson,
    bool? shareHandoutContext,
    DateTime? updatedAt,
  }) => CloudProfile(
    id: id,
    displayName: displayName ?? this.displayName,
    baseUrl: baseUrl ?? this.baseUrl,
    modelId: modelId ?? this.modelId,
    supportsVision: supportsVision ?? this.supportsVision,
    supportsJson: supportsJson ?? this.supportsJson,
    shareHandoutContext: shareHandoutContext ?? this.shareHandoutContext,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  String get chatUrl {
    final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.endsWith('/chat/completions')) return base;
    return '$base/chat/completions';
  }

  String get modelsUrl {
    final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.endsWith('/chat/completions')) {
      return '${base.substring(0, base.length - '/chat/completions'.length)}/models';
    }
    return '$base/models';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'baseUrl': baseUrl,
    'modelId': modelId,
    'supportsVision': supportsVision,
    'supportsJson': supportsJson,
    'shareHandoutContext': shareHandoutContext,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CloudProfile.fromJson(Map<String, dynamic> json) => CloudProfile(
    id: json['id'] as String,
    displayName: json['displayName'] as String? ?? 'Custom cloud AI',
    baseUrl: json['baseUrl'] as String? ?? '',
    modelId: json['modelId'] as String? ?? '',
    supportsVision: json['supportsVision'] as bool? ?? false,
    supportsJson: json['supportsJson'] as bool? ?? true,
    shareHandoutContext: json['shareHandoutContext'] as bool? ?? false,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}
