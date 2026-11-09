class AiChatSession {
  const AiChatSession({
    required this.id,
    required this.subjectId,
    required this.contextKey,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.pdfId,
  });

  final String id;
  final String subjectId;
  final String contextKey;
  final String? pdfId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Map<String, dynamic>> messages;

  String get preview {
    for (final message in messages.reversed) {
      final text = (message['text'] as String? ?? '').trim();
      if (text.isNotEmpty) return text.replaceAll(RegExp(r'\s+'), ' ');
    }
    return 'No messages yet';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'contextKey': contextKey,
    if (pdfId != null) 'pdfId': pdfId,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages,
  };

  factory AiChatSession.fromJson(Map<String, dynamic> json) => AiChatSession(
    id: json['id'] as String,
    subjectId: json['subjectId'] as String? ?? '',
    contextKey: json['contextKey'] as String? ?? '',
    pdfId: json['pdfId'] as String?,
    title: json['title'] as String? ?? 'New chat',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    messages: (json['messages'] as List<dynamic>? ?? const [])
        .map((item) => (item as Map).cast<String, dynamic>())
        .toList(growable: false),
  );
}
