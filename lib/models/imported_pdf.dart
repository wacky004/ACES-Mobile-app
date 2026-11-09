class PdfChunk {
  const PdfChunk({required this.id, required this.page, required this.text});

  final String id;
  final int page;
  final String text;

  Map<String, dynamic> toJson() => {'id': id, 'page': page, 'text': text};

  factory PdfChunk.fromJson(Map<String, dynamic> json) => PdfChunk(
    id: json['id'] as String,
    page: (json['page'] as num?)?.toInt() ?? 1,
    text: json['text'] as String? ?? '',
  );
}

class ImportedPdf {
  const ImportedPdf({
    required this.id,
    required this.filename,
    required this.pages,
    required this.createdAt,
    required this.chunks,
    required this.ocrUsed,
  });

  final String id;
  final String filename;
  final int pages;
  final DateTime createdAt;
  final List<PdfChunk> chunks;
  final bool ocrUsed;

  int get chunkCount => chunks.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'filename': filename,
    'pages': pages,
    'createdAt': createdAt.toIso8601String(),
    'chunks': chunks.map((chunk) => chunk.toJson()).toList(),
    'ocrUsed': ocrUsed,
  };

  factory ImportedPdf.fromJson(Map<String, dynamic> json) => ImportedPdf(
    id: json['id'] as String,
    filename: json['filename'] as String? ?? 'PDF',
    pages: (json['pages'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    chunks: (json['chunks'] as List<dynamic>? ?? const [])
        .map((item) => PdfChunk.fromJson((item as Map).cast<String, dynamic>()))
        .toList(growable: false),
    ocrUsed: json['ocrUsed'] as bool? ?? false,
  );
}

class DraftQuestion {
  const DraftQuestion({
    required this.id,
    required this.sourcePage,
    required this.topic,
    required this.difficulty,
    required this.stem,
    required this.options,
    required this.answerIndex,
    required this.explanation,
  });

  final String id;
  final int sourcePage;
  final String topic;
  final String difficulty;
  final String stem;
  final List<String> options;
  final int answerIndex;
  final String explanation;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourcePage': sourcePage,
    'topic': topic,
    'difficulty': difficulty,
    'stem': stem,
    'options': options,
    'answerIndex': answerIndex,
    'explanation': explanation,
  };

  factory DraftQuestion.fromJson(Map<String, dynamic> json) => DraftQuestion(
    id: json['id'] as String,
    sourcePage: (json['sourcePage'] as num?)?.toInt() ?? 1,
    topic: json['topic'] as String? ?? 'PDF',
    difficulty: json['difficulty'] as String? ?? 'medium',
    stem: json['stem'] as String? ?? '',
    options: (json['options'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false),
    answerIndex: (json['answerIndex'] as num?)?.toInt() ?? 0,
    explanation: json['explanation'] as String? ?? '',
  );
}

class DraftSet {
  const DraftSet({
    required this.id,
    required this.pdfId,
    required this.filename,
    required this.createdAt,
    required this.questions,
  });

  final String id;
  final String pdfId;
  final String filename;
  final DateTime createdAt;
  final List<DraftQuestion> questions;

  Map<String, dynamic> toJson() => {
    'id': id,
    'pdfId': pdfId,
    'filename': filename,
    'createdAt': createdAt.toIso8601String(),
    'questions': questions.map((question) => question.toJson()).toList(),
  };

  factory DraftSet.fromJson(Map<String, dynamic> json) => DraftSet(
    id: json['id'] as String,
    pdfId: json['pdfId'] as String? ?? '',
    filename: json['filename'] as String? ?? 'PDF',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    questions: (json['questions'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              DraftQuestion.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList(growable: false),
  );
}
