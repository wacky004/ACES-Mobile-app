class ReaderSection {
  const ReaderSection({
    required this.id,
    required this.title,
    required this.page,
    required this.bullets,
    required this.tableIds,
  });

  final String id;
  final String title;
  final int page;
  final List<String> bullets;
  final List<String> tableIds;

  factory ReaderSection.fromJson(Map<String, dynamic> json) => ReaderSection(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        page: (json['page'] as num?)?.toInt() ?? 1,
        bullets: (json['bullets'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(growable: false),
        tableIds: (json['tableIds'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(growable: false),
      );
}

class ReaderTerm {
  const ReaderTerm({
    required this.id,
    required this.term,
    required this.definition,
    required this.page,
    required this.aliases,
    required this.sectionId,
  });

  final String id;
  final String term;
  final String definition;
  final int page;
  final List<String> aliases;
  final String sectionId;

  factory ReaderTerm.fromJson(Map<String, dynamic> json) => ReaderTerm(
        id: json['id'] as String,
        term: json['term'] as String? ?? '',
        definition: json['definition'] as String? ?? '',
        page: (json['page'] as num?)?.toInt() ?? 1,
        aliases: (json['aliases'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(growable: false),
        sectionId: json['sectionId'] as String? ?? '',
      );
}

class ReaderTable {
  const ReaderTable({
    required this.id,
    required this.title,
    required this.headers,
    required this.rows,
    required this.page,
    required this.note,
  });

  final String id;
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  final int page;
  final String note;

  factory ReaderTable.fromJson(Map<String, dynamic> json) => ReaderTable(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        headers: (json['headers'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(growable: false),
        rows: (json['rows'] as List<dynamic>? ?? const [])
            .map((row) => (row as List<dynamic>)
                .map((cell) => cell.toString())
                .toList(growable: false))
            .toList(growable: false),
        page: (json['page'] as num?)?.toInt() ?? 1,
        note: json['note'] as String? ?? '',
      );
}

class ReaderHandout {
  const ReaderHandout({
    required this.id,
    required this.termId,
    required this.number,
    required this.title,
    required this.summary,
    required this.sections,
    required this.terms,
    required this.tables,
  });

  final String id;
  final String termId;
  final String number;
  final String title;
  final String summary;
  final List<ReaderSection> sections;
  final List<ReaderTerm> terms;
  final List<ReaderTable> tables;

  factory ReaderHandout.fromJson(Map<String, dynamic> json) => ReaderHandout(
        id: json['id'] as String,
        termId: json['termId'] as String? ?? '',
        number: json['number'] as String? ?? '',
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        sections: (json['sections'] as List<dynamic>? ?? const [])
            .map((item) =>
                ReaderSection.fromJson((item as Map).cast<String, dynamic>()))
            .toList(growable: false),
        terms: (json['terms'] as List<dynamic>? ?? const [])
            .map((item) =>
                ReaderTerm.fromJson((item as Map).cast<String, dynamic>()))
            .toList(growable: false),
        tables: (json['tables'] as List<dynamic>? ?? const [])
            .map((item) =>
                ReaderTable.fromJson((item as Map).cast<String, dynamic>()))
            .toList(growable: false),
      );

  ReaderTable? tableById(String id) {
    for (final table in tables) {
      if (table.id == id) return table;
    }
    return null;
  }

  List<ReaderTable> tablesFor(ReaderSection section) => [
        for (final id in section.tableIds) ?tableById(id),
      ];
}

class HandoutReaderPack {
  const HandoutReaderPack({
    required this.subjectId,
    required this.subject,
    required this.version,
    required this.handouts,
  });

  final String subjectId;
  final String subject;
  final String version;
  final List<ReaderHandout> handouts;

  factory HandoutReaderPack.fromJson(Map<String, dynamic> json) =>
      HandoutReaderPack(
        subjectId: json['subjectId'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        version: json['version'] as String? ?? '',
        handouts: (json['handouts'] as List<dynamic>? ?? const [])
            .map((item) =>
                ReaderHandout.fromJson((item as Map).cast<String, dynamic>()))
            .toList(growable: false),
      );

  ReaderHandout? handoutById(String id) {
    for (final handout in handouts) {
      if (handout.id == id) return handout;
    }
    return null;
  }

  List<ReaderHandout> handoutsForTerm(String termId) =>
      handouts.where((handout) => handout.termId == termId).toList();

  List<ReaderTerm> get allTerms => [
        for (final handout in handouts) ...handout.terms,
      ];
}

class ReaderFullTextPage {
  const ReaderFullTextPage({
    required this.handoutId,
    required this.page,
    required this.text,
  });

  final String handoutId;
  final int page;
  final String text;
}

enum ReaderSearchKind { handout, section, term, table }

class ReaderSearchHit {
  const ReaderSearchHit({
    required this.kind,
    required this.handout,
    required this.title,
    required this.snippet,
    this.sectionId,
    this.termId,
  });

  final ReaderSearchKind kind;
  final ReaderHandout handout;
  final String title;
  final String snippet;
  final String? sectionId;
  final String? termId;
}
