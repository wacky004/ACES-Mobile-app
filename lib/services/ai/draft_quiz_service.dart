import 'dart:convert';

import '../../models/imported_pdf.dart';
import 'ai_model_catalog.dart';
import 'ai_service.dart';
import 'prompt_builder.dart';
import 'rag_index.dart';

class DraftQuizService {
  static const _systemPrompt = '''
You create multiple-choice review questions for a college Computer Engineering course.
Use ONLY facts stated in the provided handout excerpts.
Output ONLY a valid JSON array. No markdown, no comments, no explanation outside the JSON.
Every question must have exactly 4 unique options and exactly one correct answer.
''';

  Future<List<DraftQuestion>> generate({
    required AiModelSpec model,
    required ImportedPdf pdf,
    required List<RagChunk> chunks,
    int count = 10,
    required void Function(int completed, int total, String status) onProgress,
    bool Function()? isCancelled,
  }) async {
    if (chunks.isEmpty) return const [];
    final result = <DraftQuestion>[];
    final seenStems = <String>{};
    const questionsPerBatch = 5;
    final batchCount = (count / questionsPerBatch).ceil();

    for (var batchIndex = 0; batchIndex < batchCount; batchIndex++) {
      if (isCancelled?.call() ?? false) break;
      final requested = (count - result.length).clamp(1, questionsPerBatch);
      final batch = _chunksForBatch(chunks, batchIndex, batchCount);
      if (batch.isEmpty) break;
      onProgress(
        result.length,
        count,
        'Generating questions ${result.length + 1}–'
        '${(result.length + requested).clamp(1, count)}',
      );

      var parsed = <DraftQuestion>[];
      try {
        final buffer = StringBuffer();
        await for (final token in AiService.instance.ask(
          spec: model,
          systemPrompt: _systemPrompt,
          userPrompt: PromptBuilder.draftPrompt(
            chunks: batch,
            count: requested,
          ),
          maxOutputTokens: 1200,
        )) {
          buffer.write(token);
        }
        parsed = parseQuestions(buffer.toString(), batch);
      } catch (_) {
        parsed = const [];
      }

      if (parsed.isEmpty) {
        try {
          final buffer = StringBuffer();
          await for (final token in AiService.instance.ask(
            spec: model,
            systemPrompt: _systemPrompt,
            userPrompt:
                '${PromptBuilder.draftPrompt(chunks: batch, count: requested)}\n'
                'Return ONLY the JSON array. Do not write anything else.',
            maxOutputTokens: 1200,
          )) {
            buffer.write(token);
          }
          parsed = parseQuestions(buffer.toString(), batch);
        } catch (_) {}
      }

      final now = DateTime.now().microsecondsSinceEpoch;
      for (final question in parsed) {
        final signature = question.stem.toLowerCase().trim();
        if (signature.isEmpty || !seenStems.add(signature)) continue;
        result.add(
          DraftQuestion(
            id: '${pdf.id}-$now-${result.length}',
            sourcePage: question.sourcePage,
            topic: question.topic,
            difficulty: question.difficulty,
            stem: question.stem,
            options: question.options,
            answerIndex: question.answerIndex,
            explanation: question.explanation,
          ),
        );
        if (result.length >= count) break;
      }
      onProgress(result.length, count, 'Generated ${result.length} of $count');
      if (result.length >= count) break;
    }
    return result;
  }

  /// Picks at most six chunks from this batch's slice of the document.
  List<RagChunk> _chunksForBatch(
    List<RagChunk> chunks,
    int batchIndex,
    int batchCount,
  ) {
    const maxChunks = 6;
    if (chunks.length <= maxChunks) return chunks;
    final start = (batchIndex * chunks.length / batchCount).floor();
    final end = ((batchIndex + 1) * chunks.length / batchCount).ceil();
    final segmentLength = (end - start).clamp(1, chunks.length);
    final step = (segmentLength / maxChunks).ceil().clamp(1, segmentLength);
    final selected = <RagChunk>[];
    for (
      var index = start;
      index < chunks.length && index < end && selected.length < maxChunks;
      index += step
    ) {
      selected.add(chunks[index]);
    }
    return selected;
  }

  List<DraftQuestion> parseQuestions(String raw, List<RagChunk> sourceChunks) {
    final text = raw.replaceAll('```json', '').replaceAll('```', '').trim();
    final arrayStart = text.indexOf('[');
    final arrayEnd = text.lastIndexOf(']');
    dynamic decoded;
    if (arrayStart >= 0 && arrayEnd > arrayStart) {
      decoded = _decode(text.substring(arrayStart, arrayEnd + 1));
    }
    if (decoded == null) {
      final objectStart = text.indexOf('{');
      final objectEnd = text.lastIndexOf('}');
      if (objectStart >= 0 && objectEnd > objectStart) {
        final single = _decode(text.substring(objectStart, objectEnd + 1));
        if (single is Map) decoded = [single];
      }
    }
    if (decoded is Map && decoded['questions'] is List) {
      decoded = decoded['questions'];
    }
    if (decoded is! List) return const [];

    final pages = sourceChunks.map((chunk) => chunk.page).toSet();
    final defaultPage = sourceChunks.isEmpty ? 1 : sourceChunks.first.page;
    final questions = <DraftQuestion>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final map = item.cast<String, dynamic>();
      final stem = (map['stem'] as String? ?? '').trim();
      final options = (map['options'] as List<dynamic>? ?? const [])
          .map((option) => option.toString().trim())
          .toList(growable: false);
      final answerIndex = (map['answerIndex'] as num?)?.toInt() ?? -1;
      final explanation = (map['explanation'] as String? ?? '').trim();
      if (stem.isEmpty ||
          options.length != 4 ||
          options.toSet().length != 4 ||
          answerIndex < 0 ||
          answerIndex > 3 ||
          explanation.isEmpty) {
        continue;
      }
      final rawPage = (map['sourcePage'] as num?)?.toInt();
      final page = rawPage != null && pages.contains(rawPage)
          ? rawPage
          : defaultPage;
      final difficulty = switch ((map['difficulty'] as String? ?? 'medium')
          .toLowerCase()) {
        'easy' => 'easy',
        'hard' => 'hard',
        _ => 'medium',
      };
      final rawTopic = (map['topic'] as String? ?? '').trim();
      questions.add(
        DraftQuestion(
          id: '',
          sourcePage: page,
          topic: rawTopic.isEmpty ? 'PDF' : rawTopic,
          difficulty: difficulty,
          stem: stem,
          options: options,
          answerIndex: answerIndex,
          explanation: explanation,
        ),
      );
    }
    return questions;
  }

  dynamic _decode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
}
