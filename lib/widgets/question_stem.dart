import 'package:flutter/material.dart';

class QuestionStem extends StatelessWidget {
  const QuestionStem({
    super.key,
    required this.text,
    this.underlined = '',
    required this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final String underlined;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final index = underlined.isEmpty ? -1 : text.indexOf(underlined);
    if (index < 0) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }
    final before = text.substring(0, index);
    final after = text.substring(index + underlined.length);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          TextSpan(
            text: underlined,
            style: const TextStyle(
              decoration: TextDecoration.underline,
              decorationThickness: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
