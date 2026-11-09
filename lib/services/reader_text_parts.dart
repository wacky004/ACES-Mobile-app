import '../models/handout_reader.dart';

class ReaderTextPart {
  const ReaderTextPart({
    required this.handoutId,
    required this.page,
    required this.index,
    required this.count,
    required this.text,
  });

  final String handoutId;
  final int page;
  final int index;
  final int count;
  final String text;

  String get label =>
      count <= 1 ? 'Page $page' : 'Page $page ? Part ${index + 1} of $count';
}

List<ReaderTextPart> buildReaderTextParts(
  List<ReaderFullTextPage> pages, {
  int maxChars = 1200,
}) {
  final result = <ReaderTextPart>[];
  for (final page in pages) {
    final text = page.text.trim();
    if (text.isEmpty) continue;
    final pieces = _splitPage(text, maxChars);
    for (var index = 0; index < pieces.length; index++) {
      result.add(
        ReaderTextPart(
          handoutId: page.handoutId,
          page: page.page,
          index: index,
          count: pieces.length,
          text: pieces[index],
        ),
      );
    }
  }
  return result;
}

List<String> _splitPage(String text, int maxChars) {
  if (text.length <= maxChars) return [text];
  final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
  final parts = <String>[];
  final buffer = StringBuffer();
  for (final raw in sentences) {
    final sentence = raw.trim();
    if (sentence.isEmpty) continue;
    if (sentence.length > maxChars) {
      if (buffer.isNotEmpty) {
        parts.add(buffer.toString().trim());
        buffer.clear();
      }
      var start = 0;
      while (start < sentence.length) {
        final end = (start + maxChars).clamp(0, sentence.length);
        var cut = end;
        if (end < sentence.length) {
          final space = sentence.lastIndexOf(' ', end);
          if (space > start + maxChars ~/ 2) cut = space;
        }
        parts.add(sentence.substring(start, cut).trim());
        start = cut;
        while (start < sentence.length && sentence[start] == ' ') {
          start++;
        }
      }
      continue;
    }
    if (buffer.isNotEmpty && buffer.length + sentence.length + 1 > maxChars) {
      parts.add(buffer.toString().trim());
      buffer.clear();
    }
    if (buffer.isNotEmpty) buffer.write(' ');
    buffer.write(sentence);
  }
  if (buffer.isNotEmpty) parts.add(buffer.toString().trim());
  return parts.where((part) => part.isNotEmpty).toList(growable: false);
}
