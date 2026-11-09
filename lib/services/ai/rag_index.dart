import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../../models/imported_pdf.dart';

class RagChunk {
  const RagChunk({
    required this.id,
    required this.termId,
    required this.handoutId,
    required this.handoutNumber,
    required this.handoutTitle,
    required this.page,
    required this.text,
    this.isPdf = false,
  });

  final String id;
  final String termId;
  final String handoutId;
  final String handoutNumber;
  final String handoutTitle;
  final int page;
  final String text;
  final bool isPdf;

  String get sourceLabel => isPdf
      ? '$handoutTitle · page $page'
      : 'Handout $handoutNumber · page $page';

  String get promptLabel => isPdf
      ? '[$handoutTitle, page $page]'
      : '[Handout $handoutNumber: $handoutTitle, page $page]';

  factory RagChunk.fromJson(Map<String, dynamic> json) => RagChunk(
    id: json['id'] as String,
    termId: json['termId'] as String? ?? '',
    handoutId: json['handoutId'] as String? ?? '',
    handoutNumber: json['handoutNumber'] as String? ?? '',
    handoutTitle: json['handoutTitle'] as String? ?? 'Handout',
    page: (json['page'] as num?)?.toInt() ?? 1,
    text: json['text'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'termId': termId,
    'handoutId': handoutId,
    'handoutNumber': handoutNumber,
    'handoutTitle': handoutTitle,
    'page': page,
    'text': text,
    'isPdf': isPdf,
  };

  static RagChunk fromPdfChunk(ImportedPdf pdf, PdfChunk chunk) => RagChunk(
    id: '${pdf.id}-${chunk.id}',
    termId: 'pdf',
    handoutId: pdf.id,
    handoutNumber: 'PDF',
    handoutTitle: pdf.filename,
    page: chunk.page,
    text: chunk.text,
    isPdf: true,
  );
}

class RagIndex {
  RagIndex._(this.chunks, this._terms, this._docFreq, this._avgLength);

  final List<RagChunk> chunks;
  final List<Map<String, int>> _terms;
  final Map<String, int> _docFreq;
  final double _avgLength;

  static RagIndex fromChunks(List<RagChunk> chunks) {
    final terms = <Map<String, int>>[];
    final docFreq = <String, int>{};
    var totalLength = 0;
    for (final chunk in chunks) {
      final tokens = _tokenize('${chunk.handoutTitle} ${chunk.text}');
      final counts = <String, int>{};
      for (final token in tokens) {
        counts[token] = (counts[token] ?? 0) + 1;
      }
      terms.add(counts);
      for (final token in counts.keys) {
        docFreq[token] = (docFreq[token] ?? 0) + 1;
      }
      totalLength += tokens.length;
    }
    final avgLength = chunks.isEmpty ? 1.0 : totalLength / chunks.length;
    return RagIndex._(chunks, terms, docFreq, avgLength);
  }

  static const Map<String, String> _chunkAssets = {
    'it2205': 'assets/handouts/it2205.json',
    'it2102': 'assets/handouts/it2102.json',
    'it1919': 'assets/handouts/it1919.json',
  };

  static Future<RagIndex> loadBundled() => loadForSubject('it2205');

  static Future<RagIndex> loadForSubject(String subjectId) async {
    final asset = _chunkAssets[subjectId];
    if (asset == null) return fromChunks(const []);
    final raw = await rootBundle.loadString(asset);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final chunks = (decoded['chunks'] as List<dynamic>? ?? const [])
        .map((item) => RagChunk.fromJson((item as Map).cast<String, dynamic>()))
        .toList(growable: false);
    return fromChunks(chunks);
  }

  List<RagChunk> search(String query, {Set<String>? termIds, int limit = 4}) {
    final queryTokens = _tokenize(query).toSet().toList(growable: false);
    if (queryTokens.isEmpty) {
      return chunks.take(limit).toList(growable: false);
    }
    const k1 = 1.5;
    const b = 0.75;
    final scored = <({int index, double score})>[];
    final totalDocs = chunks.length;

    for (var index = 0; index < chunks.length; index++) {
      final chunk = chunks[index];
      if (termIds != null &&
          termIds.isNotEmpty &&
          !termIds.contains(chunk.termId)) {
        continue;
      }
      final counts = _terms[index];
      final length = counts.values.fold<int>(0, (sum, value) => sum + value);
      var score = 0.0;
      for (final token in queryTokens) {
        final tf = counts[token] ?? 0;
        if (tf == 0) continue;
        final df = _docFreq[token] ?? 0;
        final idf = _idf(totalDocs, df);
        final denominator = tf + k1 * (1 - b + b * (length / _avgLength));
        score += idf * (tf * (k1 + 1)) / denominator;
      }
      if (score > 0) {
        scored.add((index: index, score: score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final selected = <int>[];
    final seen = <String>{};
    for (final result in scored) {
      final chunk = chunks[result.index];
      final signature = '${chunk.handoutId}|${chunk.page}|${chunk.text}';
      if (!seen.add(signature)) continue;
      selected.add(result.index);
      if (selected.length >= limit) break;
    }
    return selected.map((index) => chunks[index]).toList(growable: false);
  }

  static double _idf(int totalDocs, int docFreq) =>
      math.log(1 + (totalDocs - docFreq + 0.5) / (docFreq + 0.5));

  static List<String> _tokenize(String text) {
    final matches = RegExp(r'[a-z0-9]+').allMatches(text.toLowerCase());
    final tokens = <String>[];
    for (final match in matches) {
      final token = match.group(0)!;
      if (token.length < 2) continue;
      if (_stopWords.contains(token)) continue;
      tokens.add(token);
    }
    return tokens;
  }

  static const _stopWords = {
    'a',
    'an',
    'and',
    'are',
    'as',
    'at',
    'be',
    'been',
    'but',
    'by',
    'can',
    'could',
    'did',
    'do',
    'does',
    'for',
    'from',
    'had',
    'has',
    'have',
    'he',
    'her',
    'his',
    'how',
    'if',
    'in',
    'into',
    'is',
    'it',
    'its',
    'may',
    'not',
    'of',
    'on',
    'or',
    'our',
    'she',
    'should',
    'that',
    'the',
    'their',
    'them',
    'then',
    'there',
    'these',
    'they',
    'this',
    'those',
    'to',
    'was',
    'we',
    'were',
    'what',
    'when',
    'which',
    'who',
    'will',
    'with',
    'would',
    'you',
    'your',
  };
}
