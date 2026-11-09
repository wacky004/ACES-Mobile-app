import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/handout_reader.dart';
import '../../widgets/ui_kit.dart';

class ReaderTableView extends StatelessWidget {
  const ReaderTableView({
    super.key,
    required this.table,
    this.fontScale = 1,
  });

  final ReaderTable table;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark ? AppColors.darkBorder : AppColors.navy;
    final headerText = isDark ? const Color(0xFFE8EEF8) : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final cellStyle = TextStyle(
      fontSize: 11 * fontScale,
      height: 1.4,
      color: isDark ? const Color(0xFFE8EEF8) : AppColors.ink,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                const Icon(Icons.table_chart_outlined,
                    size: 17, color: AppColors.teal),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    table.title,
                    style: TextStyle(
                      fontSize: 13 * fontScale,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ),
                StatusPill(
                  label: 'page ${table.page}',
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder(
                horizontalInside: BorderSide(color: borderColor),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: headerColor),
                  children: [
                    for (final header in table.headers)
                      _Cell(
                        text: header,
                        style: cellStyle.copyWith(
                          color: headerText,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5 * fontScale,
                        ),
                        header: true,
                      ),
                  ],
                ),
                for (var rowIndex = 0;
                    rowIndex < table.rows.length;
                    rowIndex++)
                  TableRow(
                    decoration: BoxDecoration(
                      color: rowIndex.isOdd
                          ? (isDark
                              ? AppColors.darkBackground
                              : AppColors.surfaceAlt)
                          : null,
                    ),
                    children: [
                      for (var col = 0;
                          col < table.rows[rowIndex].length;
                          col++)
                        _Cell(
                          text: table.rows[rowIndex][col],
                          style: cellStyle.copyWith(
                            fontWeight:
                                col == 0 ? FontWeight.w700 : FontWeight.w400,
                            color: col == 0
                                ? (isDark
                                    ? const Color(0xFFE8EEF8)
                                    : AppColors.ink)
                                : (isDark
                                    ? AppColors.darkMuted
                                    : AppColors.muted),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          if (table.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                table.note,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.4,
                  color: AppColors.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.text, required this.style, this.header = false});

  final String text;
  final TextStyle style;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 110, maxWidth: 260),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Text(text, style: style),
      ),
    );
  }
}

Future<void> showTermSheet(
  BuildContext context, {
  required ReaderTerm term,
  required String handoutTitle,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book_rounded,
                    color: AppColors.teal, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    term.term,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                term.definition,
                style: const TextStyle(fontSize: 13.5, height: 1.55),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$handoutTitle · page ${term.page}',
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
