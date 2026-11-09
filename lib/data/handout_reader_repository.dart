import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/handout_reader.dart';

class HandoutReaderRepository {
  HandoutReaderRepository._();
  static final HandoutReaderRepository instance = HandoutReaderRepository._();

  static const Map<String, _ReaderAssets> _assets = {
    'it2205': _ReaderAssets(
      pack: 'assets/handouts/it2205_reader.json',
      chunks: 'assets/handouts/it2205.json',
    ),
    'it2102': _ReaderAssets(
      pack: 'assets/handouts/it2102_reader.json',
      chunks: 'assets/handouts/it2102.json',
    ),
    'it1919': _ReaderAssets(
      pack: 'assets/handouts/it1919_reader.json',
      chunks: 'assets/handouts/it1919.json',
    ),
  };

  final Map<String, Future<HandoutReaderPack>> _packFutures = {};
  final Map<String, Future<Map<String, List<ReaderFullTextPage>>>>
  _fullTextFutures = {};

  Future<HandoutReaderPack?> loadPackFor(String subjectId) async {
    if (!_assets.containsKey(subjectId)) return null;
    final future = _packFutures.putIfAbsent(
      subjectId,
      () => _loadPack(subjectId),
    );
    return future;
  }

  Future<HandoutReaderPack> loadPack() async {
    return (await loadPackFor('it2205'))!;
  }

  Future<HandoutReaderPack> _loadPack(String subjectId) async {
    final raw = await rootBundle.loadString(_assets[subjectId]!.pack);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return HandoutReaderPack.fromJson(decoded);
  }

  Future<Map<String, List<ReaderFullTextPage>>> _loadFullText(
    String subjectId,
  ) {
    final future = _fullTextFutures.putIfAbsent(
      subjectId,
      () => _loadFullTextInternal(subjectId),
    );
    return future;
  }

  Future<Map<String, List<ReaderFullTextPage>>> _loadFullTextInternal(
    String subjectId,
  ) async {
    final raw = await rootBundle.loadString(_assets[subjectId]!.chunks);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final chunks = decoded['chunks'] as List<dynamic>? ?? const [];
    final grouped = <String, Map<int, StringBuffer>>{};
    for (final item in chunks) {
      final map = (item as Map).cast<String, dynamic>();
      final handoutId = map['handoutId'] as String? ?? '';
      final page = (map['page'] as num?)?.toInt() ?? 1;
      final text = map['text'] as String? ?? '';
      if (handoutId.isEmpty || text.isEmpty) continue;
      final pages = grouped.putIfAbsent(handoutId, () => {});
      pages.putIfAbsent(page, StringBuffer.new).write('$text ');
    }
    return {
      for (final entry in grouped.entries)
        entry.key: [
          for (final page in entry.value.keys.toList()..sort())
            ReaderFullTextPage(
              handoutId: entry.key,
              page: page,
              text: _cleanFullText(entry.value[page]!.toString()),
            ),
        ],
    };
  }

  Future<List<ReaderFullTextPage>> fullTextFor(
    String subjectId,
    String handoutId,
  ) async {
    final all = await _loadFullText(subjectId);
    return all[handoutId] ?? const [];
  }

  List<ReaderSearchHit> search(HandoutReaderPack pack, String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    final hits = <ReaderSearchHit>[];
    for (final handout in pack.handouts) {
      void add({
        required ReaderSearchKind kind,
        required String title,
        required String text,
        String? sectionId,
        String? termId,
      }) {
        final index = text.toLowerCase().indexOf(needle);
        if (index < 0) return;
        final start = (index - 45).clamp(0, text.length);
        final end = (index + needle.length + 85).clamp(0, text.length);
        final snippet = text
            .substring(start, end)
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        hits.add(
          ReaderSearchHit(
            kind: kind,
            handout: handout,
            title: title,
            snippet: snippet,
            sectionId: sectionId,
            termId: termId,
          ),
        );
      }

      add(
        kind: ReaderSearchKind.handout,
        title: '${handout.number} · ${handout.title}',
        text: '${handout.title} ${handout.summary}',
      );
      for (final section in handout.sections) {
        add(
          kind: ReaderSearchKind.section,
          title: section.title,
          text: '${section.title} ${section.bullets.join(' ')}',
          sectionId: section.id,
        );
      }
      for (final term in handout.terms) {
        add(
          kind: ReaderSearchKind.term,
          title: term.term,
          text: '${term.term} ${term.definition}',
          sectionId: term.sectionId,
          termId: term.id,
        );
      }
      for (final table in handout.tables) {
        add(
          kind: ReaderSearchKind.table,
          title: table.title,
          text:
              '${table.title} ${table.headers.join(' ')} ${table.rows.expand((row) => row).join(' ')}',
        );
      }
    }
    hits.sort((a, b) => a.kind.index.compareTo(b.kind.index));
    return hits.take(30).toList(growable: false);
  }

  static String _cleanFullText(String value) {
    var text = value
        .replaceAll(
          RegExp(r'student\.feedback@sti\.edu', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\*Property of STI', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bIT\d{4}\b'), '')
        .replaceAll(RegExp(r'\b\d{2} Handout 1\b'), '')
        .replaceAll(RegExp(r'Page \d+ of \d+', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'[\uE000-\uF8FF]'), '');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static List<String> validatePack(HandoutReaderPack pack) {
    final problems = <String>[];
    if (pack.handouts.isEmpty) problems.add('No handouts found.');
    final handoutIds = <String>{};
    final termIds = <String>{};
    final tableIds = <String>{};
    for (final handout in pack.handouts) {
      if (!handoutIds.add(handout.id)) {
        problems.add('Duplicate handout id: ${handout.id}');
      }
      if (handout.sections.isEmpty) {
        problems.add('${handout.id} has no sections.');
      }
      if (handout.terms.isEmpty) {
        problems.add('${handout.id} has no terms.');
      }
      final localTables = <String>{};
      for (final table in handout.tables) {
        if (!tableIds.add(table.id)) {
          problems.add('Duplicate table id: ${table.id}');
        }
        localTables.add(table.id);
        if (table.headers.length < 2) {
          problems.add('${table.id} needs at least two headers.');
        }
        for (final row in table.rows) {
          if (row.length != table.headers.length) {
            problems.add('${table.id} has a row with the wrong column count.');
          }
        }
      }
      for (final section in handout.sections) {
        if (section.title.isEmpty) {
          problems.add('${handout.id} has a section without a title.');
        }
        for (final tableId in section.tableIds) {
          if (!localTables.contains(tableId)) {
            problems.add('${handout.id}/${section.id} references $tableId.');
          }
        }
      }
      for (final term in handout.terms) {
        if (!termIds.add(term.id)) {
          problems.add('Duplicate term id: ${term.id}');
        }
        if (term.term.isEmpty || term.definition.isEmpty) {
          problems.add('${handout.id} has an empty term or definition.');
        }
      }
    }
    return problems;
  }
}

class _ReaderAssets {
  const _ReaderAssets({required this.pack, required this.chunks});
  final String pack;
  final String chunks;
}
